#!/bin/bash

S3_PATH=$1

# Define SNAPR reference files
SNAPR_EXEC=${ROOT_DIR}bin/snapr/snapr

GENOME=/mnt/genome20
TRANSCRIPTOME_DIR=/mnt/transcriptome20
ENSEMBL=/mnt/Homo_sapiens.GRCh38.77.gtf

MODE=single


# Specify directories
ROOT_DIR=/$2/
SNAPR_VOL=/mnt/
TMP_DIR=${SNAPR_VOL}${PREFIX}_tmp/

while getopts "p1:2:g:t:e:h" ARG; do
	case "$ARG" in
	    p ) MODE=paired;;
	    1 ) PATH1=$OPTARG;;
	    2 ) PATH2=$OPTARG;;
		g ) GENOME=$OPTARG;;
		t ) TRANSCRIPTOME=$OPTARG;;
		e ) ENSEMBL=$OPTARG;;
		h ) usage; exit 0;;
		* ) usage; exit 1;;
	esac
done
shift $(($OPTIND - 1))

echo "$MODE $GENOME $PATH1"

# Parse S3 file path
# S3_DIR=$(dirname $S3_PATH)
# FILE_NAME=$(basename $S3_PATH)
# PREFIX=${FILE_NAME%.bam}
# echo $PREFIX
# 
# Create temporary directory for input files
# if [ ! -e "$TMP_DIR" ]; then
#     mkdir "$TMP_DIR"
# fi
# 
# Download S3 file
# INPUT_FILE=${TMP_DIR}${FILE_NAME}
# echo "Copying $S3_PATH to $INPUT_FILE"
# 
# aws s3 cp \
#     $S3_PATH \
#     $INPUT_FILE ;
# 
# Define SNAPR output file
# OUTPUT_FILE=${TMP_DIR}${PREFIX}.snap.bam
# 
# Run SNAPR
# time $SNAPR_EXEC $MODE \
#     $GENOME \
#     $TRANSCRIPTOME \
#     $ENSEMBLE \
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
