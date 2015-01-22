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


######## Parse inputs #########################################################

function usage {
	echo "$0: [-m mode (paired/single)] [-r] -1 s3://path_to_file [-2 s3://path_to_paired_file] [-l pair_file_label] [-g genome_index] [-t transcriptome_index] [-x ref_transcriptome]"
	echo
}

while getopts "m:r1:2:l:g:t:e:h" ARG; do
	case "$ARG" in
	    m ) MODE=$OPTARG;;
	    r ) REPROCESS=1;;
	    1 ) PATH1=$OPTARG;;
	    2 ) PATH2=$OPTARG;;
	    l ) PAIR_LABEL=$OPTARG;;
		g ) GENOME=$OPTARG;;
		t ) TRANSCRIPTOME=$OPTARG;;
		x ) GTF_FILE=$OPTARG;;
		h ) usage; exit 0;;
		* ) usage; exit 1;;
	esac
done
shift $(($OPTIND - 1))


######## Assemble & prepare data for snapr ####################################

# Function to pull out sample IDs from file paths
function get_id {
    filename=${line##*/};
    fileid=${filename%%.*}
    echo $fileid;
    < $1
}

# Parse S3 file path
S3_DIR=$(dirname $PATH1)
S3_UPDIR=${S3_DIR%/*}

# echo $S3_UPDIR

FILE_NAME=${PATH1##*/}
if [ $REPROCESS == 0 ];
then
    PREFIX=${FILE_NAME%.*.*};
else
    PREFIX=${FILE_NAME%.*};
fi

# If processing multiple FASTQ files, create a single name for the output file
if [ $MODE == paired ] && [ $REPROCESS == 0 ];
then
    PREFIX=$(echo $PREFIX \
        | awk -v tag="$PAIR_LABEL" '{gsub(tag, "_")}1')
fi
    
# Create temporary directory for input files
TMP_DIR=/results/${PREFIX}_tmp/
# if [ ! -e "$TMP_DIR" ]; then
#     mkdir "$TMP_DIR"
# fi

FILE1=${TMP_DIR}${FILE_NAME}

# Download S3 files
echo "Copying $PATH1 to $FILE1"
# aws s3 cp \
#     $PATH1 \
#     $FILE1 ;
echo

# Get second FASTQ file if necessary
if [ $MODE == paired ] && [ $REPROCESS = 0 ];
then
    FILE2=${TMP_DIR}${PATH2##*/}
    
    echo "Copying $PATH2 to $FILE2"
    # aws s3 cp \
    #     $PATH2 \
    #     $FILE2 ;
    echo
fi

# Define set of input files; if FILE2 is unassigned, only FILE1 will be used
INPUT="${FILE1} ${FILE2}"

######## Assemble options for running snapr ##################################

SNAPR_EXEC="snapr"

# Define SNAPR output file
OUTPUT_FILE=${TMP_DIR}${PREFIX}.snap.bam

REF_FILES="${GENOME} ${TRANSCRIPTOME} ${GTF_FILE}"
OTHER="-M -rg ${PREFIX} -so -ku"

SNAPR_OPTIONS="${MODE} ${REF_FILES} ${INPUT} -o ${OUTPUT_FILE} ${OTHER}"

echo "$SNAPR_EXEC $SNAPR_OPTIONS"

# Run SNAPR
# time $SNAPR_EXEC $SNAPR_OPTIONS

######## Copy and clean up results ############################################

# Remove original file
# rm $INPUT_FILE
# 
# Copy files to S3
# aws s3 cp \
#     $TMP_DIR \
#     $S3_DIR/snapr/ \
#     --recursive ;
# 
# Remove temporary directory
# rm -rf $TMP_DIR
