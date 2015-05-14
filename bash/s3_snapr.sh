#!/bin/bash

# Given a path to a file on S3 (or two files, in the case of paired-end FASTQ
# data, this script downloads the data, processes the file(s) with SNAPR, and
# uploads the results back to the original bucket.

######## Specify defaults & examples ##########################################

# Default options for file format and alignment mode
MODE=paired
REPROCESS=0
PAIR_LABEL="_R[1-2]_"

# Default reference paths
GENOME="/resources/genome/"
TRANSCRIPTOME="/resources/transcriptome/"
GTF_FILE="/resources/assemblies/ref-transcriptome.gtf"

# Default behavior for script
KEEP=0 # 0: upload outputs to S3 vs. 1: keep on local machine

######## Parse inputs #########################################################

function usage {
	echo "$0: [-m mode (paired/single)] [-r] -d dir_name -1 s3://path_to_file [-2 s3://path_to_paired_file] [-l pair_file_label] [-g genome_index] [-t transcriptome_index] [-x ref_transcriptome] [-k]"
	echo
}

function checkS3BucketIntegrity {
    PID=`echo $$`
    S3_OUT_DIR=$1
    LOCAL_DIR=$2
    aws s3 ls $S3_OUT_DIR | awk '{print $3}' | sort > /tmp/s3-output$PID
    ls -la $LOCAL_DIR | awk '{print $5}' | tail -n +4 | sort > /tmp/fs-output$PID
    echo `diff /tmp/s3-output$PID /tmp/fs-output$PID`
}

while getopts "m:rd:1:2:l:g:t:x:kh" ARG; do
	case "$ARG" in
	    m ) MODE=$OPTARG;;
	    r ) REPROCESS=1;;
		d ) S3_DIR=$OPTARG;;
	    1 ) PATH1=$OPTARG;;
	    2 ) PATH2=$OPTARG;;
	    l ) PAIR_LABEL=$OPTARG;;
	    g ) GENOME=$OPTARG;;
	    t ) TRANSCRIPTOME=$OPTARG;;
	    x ) GTF_FILE=$OPTARG;;
	    k ) KEEP=1;;
	    h ) usage; exit 0;;
	    * ) usage; exit 1;;
	esac
done
shift $(($OPTIND - 1))


######## Assemble & prepare data for snapr ####################################

# Parse S3 file path
FILE_NAME=${PATH1##*/}

if ( echo $FILE_NAME | grep -q .gz );
then
    PREFIX=${FILE_NAME%.*.*};
else
    PREFIX=${FILE_NAME%.*};
fi

# If processing multiple FASTQ files, create a single name for the output file
if [ $MODE == paired ] && [ $REPROCESS == 0 ];
then
    PREFIX=$(echo $PREFIX \
        | awk -v tag="$PAIR_LABEL" '{gsub(tag, "")}1')
fi

# Create temporary directory for input files
TMP_DIR=/data/${PREFIX}_tmp/
if [ ! -e "$TMP_DIR" ]; then
    mkdir "$TMP_DIR"
fi

FILE1=${TMP_DIR}${FILE_NAME}

# Download S3 files
echo "Copying $PATH1 to $FILE1"
aws s3 cp \
    $PATH1 \
    $FILE1 ;
echo

# Get second FASTQ file if necessary
if [ $MODE == paired ] && [ $REPROCESS = 0 ];
then
    FILE2=${TMP_DIR}${PATH2##*/}

    echo "Copying $PATH2 to $FILE2"
    aws s3 cp \
        $PATH2 \
        $FILE2 ;
    echo
fi
echo

# Define set of input files; if FILE2 is unassigned, only FILE1 will be used
INPUT="${FILE1} ${FILE2}"

######## Assemble options for running snapr ##################################

SNAPR_EXEC="snapr"

# Define SNAPR output file
OUT_DIR=/results/${PREFIX}_results/
mkdir "$OUT_DIR"
OUTPUT_FILE=${OUT_DIR}${PREFIX}.snap.bam

REF_FILES="${GENOME} ${TRANSCRIPTOME} ${GTF_FILE}"
OTHER="-M -rg ${PREFIX} -so -ku"

SNAPR_OPTIONS="${MODE} ${REF_FILES} ${INPUT} -o ${OUTPUT_FILE} ${OTHER}"

echo "$SNAPR_EXEC $SNAPR_OPTIONS"

# Run SNAPR
time $SNAPR_EXEC $SNAPR_OPTIONS

######## Copy and clean up results ############################################

MAX_S3_UPLOAD_RETRIES=5
NUM_TRIES=0

if [ ${KEEP} == 0 ]; then
    DIFF="  "

    while [ -n "$DIFF" ] && [ $NUM_TRIES -lt $MAX_S3_UPLOAD_RETRIES ] 
    do
    # Copy snapr output files to S3
    aws s3 cp \
        $OUT_DIR \
        $S3_DIR/snapr/ \
        --recursive ;

        DIFF=`checkS3BucketIntegrity $S3_DIR/snapr $OUT_DIR`
	if [ -n "$DIFF" ]; then
            let NUM_TRIES++
	    echo "S3 upload for $OUT_DIR has FAILED on trial $NUM_TRIES. Retrying."
	else
	    echo "S3 upload for $OUT_DIR has SUCCEEDED! on trial $NUM_TRIES"
	fi
    done

    if [ -n "$DIFF" ]; then
        echo "S3 upload for $OUT_DIR has FAILED after $NUM_TRIES attempts. Giving up."
        exit 1
    fi

    # Remove temporary directories
    rm -rf $TMP_DIR
	rm -rf $OUT_DIR
fi
