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

NUM_FILES=$(wc -l snapr_output_files.txt | awk '{print $1}')
echo "$NUM_FILES files detected..."
# NUM_FILES=1

for FILE_NUM in $(seq 1 $NUM_FILES); do
    
    echo "Copying file $FILE_NUM of $NUM_FILES..."
    FILE=$(awk -v r=$FILE_NUM 'NR==r{print;exit}' snapr_output_files.txt)
    S3_PATH=$BUCKET/$FILE
    
    LOCAL_PATH=$RESULTS_DIR/$FILE
    
    aws s3 cp $S3_PATH $LOCAL_PATH
done