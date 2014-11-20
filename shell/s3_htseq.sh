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
aws s3 cp \
    $S3_PATH \
    $INPUT_FILE ;

# Define HTSeq output file
PREFIX=${$FILE_NAME%.bam}
OUTPUT_FILE=${TMP_DIR}${PREFIX}.counts.txt

# Define reference files
ASSEMBLY_NAME=Homo_sapiens.GRCh38
ASSEMBLY_VER=.77
GTF_FILE=${SNAPR_VOL}${ASSEMBLY_NAME}${ASSEMBLY_VER}.gtf

# Define executables
SAMTOOLS_EXEC=${ROOT_DIR}bin/samtools-0.1.19/samtools
HTSEQ_EXEC=${ROOT_DIR}bin/HTSeq-0.6.1/build/scripts-2.7/htseq-count

$SAMTOOLS_EXEC view -h $INPUT_FILE | $HTSEQ_EXEC $GTF_FILE > $OUTPUT_FILE