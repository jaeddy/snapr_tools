#!/bin/bash

# This script is used to to download all SNAPR outputs from an S3 bucket to a
# local directory.

######## Specify inputs #######################################################

BUCKET=$1
OUT_DIR=$2
SUBDIR=$3

# Get full list of all BAM files from S3 bucket for the specified group
OUTPUT_FILES=`mktemp snapr-outputs.XXX`
aws s3 ls ${BUCKET}/${SUBDIR} --recursive \
    | grep snapr \
    | grep .txt$ \
    | awk '{print $4}' \
    > $OUTPUT_FILES

RESULTS_DIR=snapr_results

if [ ! -e ${OUT_DIR}${RESULTS_DIR} ]; then
    mkdir ${OUT_DIR}${RESULTS_DIR}
fi

NUM_FILES=$(wc -l $OUTPUT_FILES | awk '{print $1}')
echo "$NUM_FILES files detected..."

count=0
cat $OUTPUT_FILES | while read FILE; do
    count=$(($count+1)) # counter for tracking progress
    if [ $count -gt 1 ]; then
        break
    fi

    echo "Copying file $count of $NUM_FILES..."
    aws s3 cp --dryrun \
        ${BUCKET}/${FILE} \
        ${OUT_DIR}${RESULTS_DIR}/${FILE}
done

rm $OUTPUT_FILES
