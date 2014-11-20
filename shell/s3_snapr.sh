#!/bin/sh

S3_PATH=$1

# Parse S3 file path
S3_DIR=$(dirname $S3_PATH)
FILE_NAME=$(basename $S3_PATH)
echo $FILE_NAME

# Specify directories
ROOT_DIR=/$2/
TMP_DIR=./tmp/
SNAPR_VOL=/mnt/

# Create temporary directory for input files
if [ ! -e "$TMP_DIR" ]; then
    mkdir "$TMP_DIR"
fi

# Download S3 file
INPUT_FILE=${TMP_DIR}${FILE_NAME}
echo "Copying $S3_PATH to $INPUT_FILE"
#aws s3 cp \
#    $S3_PATH \
#    $INPUT_FILE ;

# Define SNAPR output file
PREFIX=${FILE_NAME%.bam}
OUTPUT_FILE=${TMP_DIR}${PREFIX}.snap.bam

# Define SNAPR reference files
ASSEMBLY_NAME=Homo_sapiens.GRCh38
ASSEMBLY_VER=.77

SNAPR_EXEC=${ROOT_DIR}bin/snapr/snapr
GENOME_DIR=${SNAPR_VOL}genome20
TRANSCRIPTOME_DIR=${SNAPR_VOL}transcriptome20
GTF_FILE=${SNAPR_VOL}${ASSEMBLY_NAME}${ASSEMBLY_VER}.gtf

# Run SNAPR
$SNAPR_EXEC paired \
    $GENOME_DIR \
    $TRANSCRIPTOME_DIR \
    $GTF_FILE \
    $INPUT_FILE \
    -o $OUTPUT_FILE \
    -M \
    -rg $PREFIX \
    -so ;
