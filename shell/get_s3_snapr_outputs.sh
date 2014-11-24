#!/bin/sh

BUCKET=$1

# Get full list of all BAM files from S3 bucket for the specified group
aws s3 ls ${BUCKET} --recursive \
    | grep snapr \
    | grep .txt$ \
    | awk '{print $4}' \
    > snapr_output_files.txt

RESULTS_DIR=./snapr_results

if [ ! -e $RESULTS_DIR ]; then
    mkdir $RESULTS_DIR
fi

NUM_FILES=1
#NUM_FILES=$(wc -l snapr_output_files.txt | awk '{print $1}')
#echo $NUM_FILES

for FILE_NUM in $(seq 1 $NUM_FILES); do
    
#    echo $FILE_NUM
    FILE=$(awk -v r=$FILE_NUM 'NR==r{print;exit}' snapr_output_files.txt)
    S3_PATH=$BUCKET/$FILE
    echo $S3_PATH
    
    LOCAL_PATH=$RESULTS_DIR/$FILE
    echo $LOCAL_PATH
    
    aws s3 cp $S3_PATH $LOCAL_PATH
done