#!/bin/sh

S3_PATH=$1

# Parse S3 file path
S3_DIR=$(dirname $S3_PATH)
FILE_NAME=$(basename $S3_PATH)
echo $FILE_NAME

# Specify directories
ROOT_DIR=./
TMP_DIR=${ROOT_DIR}tmp/

# Create temporary directory for input files
if [ ! -e "$TMP_DIR" ]; then
    mkdir "$TMP_DIR"
fi

# Download S3 file
INPUT_FILE=${TMP_DIR}${FILE_NAME}
aws s3 cp \
    $S3_PATH \
    $INPUT_FILE ;

# Define SNAPR output file
PREFIX=${$FILE_NAME%.bam}
OUTPUT_FILE=${TMP_DIR}${PREFIX}.snap.bam

# Define SNAPR reference files
SNAPR_EXEC=/bin/snap/snapr
GENOME_FILE=/mnt/genome20
TRANSCRIPTOME_FILE=/mnt/transcriptome20
GTF_FILE=/mnt/Homo_sapiens.GRCh37.68.gtf
CONTAM_FILE=/mnt/contamination20


# Run SNAPR
# time $SNAPR_EXEC paired \
#     $GENOME_FILE \
#     $TRANSCRIPTOME_FILE \
#     $GTF_FILE \
#     $INPUT_FILE \
#     -o $OUTPUT_FILE \
#     -M \
#     -rg $PREFIX \
#     -so ;