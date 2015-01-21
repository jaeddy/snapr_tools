#!/bin/bash

GENOME=/resources/genome20
TRANSCRIPTOME_DIR=/resources/transcriptome20
ENSEMBL=/resources/Homo_sapiens.GRCh38.77.gtf

MODE=paired
REPROCESS=0
PATH2=""
PAIR_LABEL="_R[1-2]_"

function usage {
	echo "$0: [-m mode (paired/single)] [-r] -1 s3://path_to_file [-2 s3://path_to_paired_file] [-l pair_file_label] [-g genome_index] [-t transcriptome_index] [-e ref_transcriptome]"
	echo
}

while getopts "mr1:2:lg:t:e:h" ARG; do
	case "$ARG" in
	    m ) MODE=$OPTARG;;
	    r ) REPROCESS=1;;
	    1 ) PATH1=$OPTARG;;
	    2 ) PATH2=$OPTARG;;
	    l ) PAIR_LABEL=$OPTARG;;
		g ) GENOME=$OPTARG;;
		t ) TRANSCRIPTOME=$OPTARG;;
		e ) ENSEMBL=$OPTARG;;
		h ) usage; exit 0;;
		* ) usage; exit 1;;
	esac
done
shift $(($OPTIND - 1))

# Function to pull out sample IDs from file paths
function get_id {
    filename=${line##*/};
    fileid=${filename%%.*}
    echo $fileid;
    < $1
}

# Parse S3 file path
S3_DIR=$(dirname $PATH1)
FILE_NAME=${PATH1##*/}
PREFIX=${FILE_NAME%.*.*}

# If processing multiple FASTQ files, create a single name for the output file
if [ $MODE == paired ] && [ $REPROCESS == 0 ];
then
    PREFIX=$(echo $PREFIX | awk '{gsub("_R[1-2]_", "_")}1')
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

INPUT="${FILE1} ${FILE2}"

# Define SNAPR output file
OUTPUT_FILE=${TMP_DIR}${PREFIX}.snap.bam

OPTIONS="${MODE} ${GENOME} ${TRANSCRIPTOME} ${ENSEMBL} ${INPUT} -o ${OUTPUT_FILE} -M -rg ${PREFIX} -so -ku"

echo $OPTIONS

# Run SNAPR
# time snapr $MODE \
#     $GENOME \
#     $TRANSCRIPTOME \
#     $ENSEMBL \
#     $INPUT_FILE \
#     -o $OUTPUT_FILE \
#     -M \
#     -rg $PREFIX \
#     -so \
#     -ku ;
# 
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
