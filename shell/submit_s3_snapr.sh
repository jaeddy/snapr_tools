#!/bin/sh

# Get full list of all BAM files from S3 bucket
aws s3 ls s3://mayo-prelim-rnaseq/ --recursive | grep .bam$ | awk '{print $4}' > bam_files.txt

NUM_FILES=1
#NUM_FILES=$(wc -l bam_files.txt | awk '{print $1}')
#echo $NUM_FILES

for FILE_NUM in $(seq 1 $NUM_FILES); do
    
#    echo $FILE_NUM
    FILE=$(awk -v r=$FILE_NUM 'NR==r{print;exit}' bam_files.txt)
    echo $FILE
    S3_PATH=s3://mayo-prelim-rnaseq/$FILE
    echo $S3_PATH
    
done

# while read line; do
#     
#     echo $line ;
# 
# done < bam_files.txt

