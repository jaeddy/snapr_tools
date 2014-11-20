#!/bin/sh

S3_PATH=$1

FILE_NAME=$(basename $S3_PATH)

echo $FILE_NAME

# Define SNAPR reference files
# SNAPR_EXEC=/snapr/bin/snap/snapr
# GENOME_FILE=/mnt/snapr/genome20
# TRANSCRIPTOME_FILE=/mnt/snapr/transcriptome20
# GTF_FILE=/mnt/snapr/Homo_sapiens.GRCh37.68.gtf
# CONTAM_FILE=/mnt/snapr/contamination20

# Define SNAPR settings
# PROCS=8
# c?
# d?

# Define input files
# INPUT_FILE_1=
# INPUT_FILE_2=

# Run SNAPR
# time $SNAPR_EXEC paired \
#     $GENOME_FILE \
#     $TRANSCRIPTOME_FILE \
#     $GTF_FILE \
#     $INPUT_FILE_1 \
#     $INPUT_FILE_2 \
#     -o $OUTPUT_FILE \
#     -t $PROCS \
#     -M \
#     -c 2 \
#     -d 4 \
#     -s 0 20000 \
#     -rg $PREFIX \
#     -ct $CONTAM_FILE \
#     -so ;