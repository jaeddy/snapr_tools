#!/bin/bash

# This script is used to check whether all source files from an S3 bucket have
# been successfully processed (with results uploaded) by SNAPR.

######## Specify inputs #######################################################

# BUCKET="s3://mayo-prelim-rnaseq"
# SUBDIR="PSP_Samples"
# EXTENSION=.bam

BUCKET=$1
SUBDIR=$2
PAIR_LABEL=$3

# Get full list of all files from S3 bucket for the specified group
FILE_LIST=`mktemp s3-seq-files.XXXXXXXX`
aws s3 ls ${BUCKET}/${SUBDIR} --recursive \
    | grep -e ".fastq" -e ".bam$" \
    | awk '{print $4}' \
    > $FILE_LIST ;

# Pull out list of source files
SOURCE_FILES=`mktemp s3-source-files.XXXXXXXX`
grep -v .snap $FILE_LIST | grep -v "^$" > $SOURCE_FILES
echo "$(wc -l $SOURCE_FILES | awk '{print $1}') total source files detected..."

# Pull out list of output SNAPR files
SNAPR_FILES=`mktemp s3-snapr-files.XXXXXXXX`
grep .snap $FILE_LIST | grep -v "^$" > $SNAPR_FILES
echo "$(wc -l $SNAPR_FILES | awk '{print $1}') SNAPR-processed files detected..."


# If no pair label is provided, assign a dummy expression
if [ -z ${PAIR_LABEL} ]; then
    PAIR_LABEL="_[1-2]"
fi

# Function to pull out sample IDs from file paths
function get_handle {
    while read line; do
        filename=${line##*/};
        handle=$(echo $filename \
            | awk -v tag="(${PAIR_LABEL})+" '{gsub(tag, "")}1' \
            | awk -v ext=".(snap|bam|fastq)+.*" '{gsub(ext, "")}1')
        echo $handle;
    done < $1
}

NUM_FILES=$(get_handle $SOURCE_FILES | uniq | wc -l | awk '{print $1}')
echo "$NUM_FILES unique source files detected..."

# Find any sample IDs in the source data that are not present in outputs
MISSED=`mktemp missed-files.XXXXXXXX`
comm -23 <(get_handle $SOURCE_FILES | uniq | sort) \
    <(get_handle $SNAPR_FILES | uniq | sort) > $MISSED

NUM_MISSED=$(wc -l $MISSED | awk '{print $1}')

if [ $NUM_MISSED -gt 0 ]; then
    echo "${NUM_MISSED} files missed."

    OUT_FILE=${BUCKET}_${SUBDIR}_missed.txt
    OUT_FILE=${OUT_FILE##*/};

    # this step is a little hacky - source files need to be converted to
    # handles in order to find matches to the list of missing files; I use grep
    # to get the line number of the match, then awk to print out the full name
    # of the source file
    echo "Saving list to ${OUT_FILE}..."
    grep -n -f $MISSED <(get_handle $SOURCE_FILES) \
        | awk -v file="\:+.*" '{gsub(file, "")}1' \
        | while read line; do
            awk -v num=$line 'NR==num {print $0}' $SOURCE_FILES
        done > $OUT_FILE
else
    echo "No files missed."
fi

rm $FILE_LIST
rm $SOURCE_FILES
rm $SNAPR_FILES
rm $MISSED
