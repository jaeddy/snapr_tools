#!/bin/bash

# BUCKET="s3://mayo-prelim-rnaseq"
# SUBDIR="PSP_Samples"
# EXTENSION=.bam

BUCKET=$1
SUBDIR=$2
EXTENSION=$3

# Get full list of all files from S3 bucket for the specified group
FILE_LIST=`mktemp s3-seq-files.XXXXXXXX`
aws s3 ls ${BUCKET}/${SUBDIR} --recursive \
    | grep -e "${EXTENSION}$" -e ".bam$" \
    | awk '{print $4}' \
    > $FILE_LIST ;

# Pull out list of source files
SOURCE_FILES=`mktemp s3-source-files.XXXXXXXX`
grep -v .snap $FILE_LIST > $SOURCE_FILES
echo $(wc -l < $SOURCE_FILES)

# Pull out list of output SNAPR files
SNAPR_FILES=`mktemp s3-snapr-files.XXXXXXXX`
grep .snap $FILE_LIST > $SNAPR_FILES
echo $(wc -l < $SNAPR_FILES)

# Function to strip filenames, leaving only sample ID
function get_id {
    while read line 
    do
        filename=${line##*/};
        fileid=${filename%%.*}
        echo $fileid;
    done < $1
} 

# Find any sample IDs in the source data that are not present in outputs
MISSED_IDS=`mktemp missed-files.XXXXXXXX`
comm -23 <(get_id $SOURCE_FILES) <(get_id $SNAPR_FILES) > $MISSED_IDS

grep -f $MISSED_IDS $SOURCE_FILES

rm $FILE_LIST
rm $SOURCE_FILES
rm $SNAPR_FILES
rm $MISSED_IDS