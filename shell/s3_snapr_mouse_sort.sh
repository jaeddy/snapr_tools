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
INPUT_FILE=${TMP_DIR}${FILE_NAME}_sorted
echo "Copying $S3_PATH to $INPUT_FILE"
aws s3 cp \
    $S3_PATH \
    $INPUT_FILE ;

# Define SNAPR output file
OUTPUT_FILE=${TMP_DIR}${PREFIX}.snap.bam

# Define samtools executable
SAMTOOLS_EXEC=${ROOT_DIR}bin/samtools-0.1.19/samtools
SORTED_FILE=${TMP_DIR}${PREFIX}.sorted

# Define SNAPR reference files
ASSEMBLY_NAME=Mus_musculus.GRCm38
ASSEMBLY_VER=.75

SNAPR_EXEC=${ROOT_DIR}bin/snapr/snapr
GENOME_DIR=${SNAPR_VOL}genome20_mouse
TRANSCRIPTOME_DIR=${SNAPR_VOL}transcriptome20_mouse
GTF_FILE=${SNAPR_VOL}${ASSEMBLY_NAME}${ASSEMBLY_VER}.gtf

# Run samtools
$SAMTOOLS_EXEC sort $INPUT_FILE $SORTED_FILE

# Run SNAPR
time $SNAPR_EXEC paired \
    $GENOME_DIR \
    $TRANSCRIPTOME_DIR \
    $GTF_FILE \
    $SORTED_FILE \
    -o $OUTPUT_FILE \
    -M \
    -rg $PREFIX \
    -so  ;

# Remove original file
#rm $INPUT_FILE

# Copy files to S3
#aws s3 cp \
#    $TMP_DIR \
#    $S3_DIR/snapr/ \
#    --recursive ;

# Remove temporary directory
#rm -rf $TMP_DIR
