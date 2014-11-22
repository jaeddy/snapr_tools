#!/bin/sh

BUCKET=$1
GROUP=$2
EBS_NAME=$3

# Get full list of all BAM files from S3 bucket for the specified group
aws s3 ls ${BUCKET}/${GROUP} --recursive | grep .bam$ | awk '{print $4}' > ${GROUP}_bam_files.txt

NUM_FILES=1
#NUM_FILES=$(wc -l bam_files.txt | awk '{print $1}')
#echo $NUM_FILES

SCRIPT_PATH=/${EBS_NAME}/snapr_tools/shell/s3_snapr.sh

for FILE_NUM in $(seq 1 $NUM_FILES); do
    
#    echo $FILE_NUM
    FILE=$(awk -v r=$FILE_NUM 'NR==r{print;exit}' ${GROUP}_bam_files.txt)
    S3_PATH=$BUCKET/$FILE

    qsub -V -pe orte 16 \
        -b y $SCRIPT_PATH $S3_PATH $EBS_NAME ;
    
done

# while read line; do
#     
#     echo $line ;
# 
# done < bam_files.txt

