#!/bin/sh

S3_PATH=$1

# Parse S3 file path
S3_DIR=$(dirname $S3_PATH)
FILE_NAME=$(basename $S3_PATH)
PREFIX=${FILE_NAME%.bam}
echo $PREFIX

# Specify directories
ROOT_DIR=/$2/
SNAPR_VOL=/mnt/
TMP_DIR=${SNAPR_VOL}${PREFIX}_tmp/

# Create temporary directory for input files
if [ ! -e "$TMP_DIR" ]; then
    mkdir "$TMP_DIR"
fi

# Download S3 file
INPUT_FILE=${TMP_DIR}${FILE_NAME}
echo "Copying $S3_PATH to $INPUT_FILE"
aws s3 cp \
    $S3_PATH \
    $INPUT_FILE ;

# Define SNAPR output file
OUTPUT_FILE=${TMP_DIR}${PREFIX}.snap.bam

# Define SNAPR reference files
ASSEMBLY_NAME=Homo_sapiens.GRCh38
ASSEMBLY_VER=.77

SNAPR_EXEC=${ROOT_DIR}bin/snapr/snapr
GENOME_DIR=${SNAPR_VOL}genome20
TRANSCRIPTOME_DIR=${SNAPR_VOL}transcriptome20
GTF_FILE=${SNAPR_VOL}${ASSEMBLY_NAME}${ASSEMBLY_VER}.gtf

# Run SNAPR
#$SNAPR_EXEC paired \
#    $GENOME_DIR \
#    $TRANSCRIPTOME_DIR \
#    $GTF_FILE \
#    $INPUT_FILE \
#    -o $OUTPUT_FILE \
#    -M \
#    -rg $PREFIX \
#    -so \
#    -ku ;

# Remove original file
rm $INPUT_FILE

touch $TMP_DIR/test

# Copy files to S3
aws s3 cp \
    $TMP_DIR \
    $S3_DIR/snapr/ \
    --recursive ;

# Remove temporary directory
#rm -rf $TMP_DIR
