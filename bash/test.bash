#!/bin/bash

# BUCKET="s3://mayo-prelim-rnaseq"
# SUBDIR="AD_Samples"
BUCKET="s3://ufl-u01-rnaseq"

NUM=16
STR="230.0G"
NAME='default'
FILE1='file1.fastq'
FILE2='file2.fastq'
FORMAT=fastq

function usage {
	echo "$0: [-m mem(3.8G,15.8G) [-p num_slots] [-q queue] [-N jobname] [-e email_address] [-g] -p prefix -1 file1.fastq -2 file2.fastq -o output_dir -b"
	echo
}

while getopts "b:n:s:N:1:2:f:h" ARG; do
	case "$ARG" in
	    b ) BUCKET=$OPTARG;;
		n ) NUM=$OPTARG;;
		s ) STR=$OPTARG;;
		N ) NAME=$OPTARG;;
        1 ) FILE1=$OPTARG;;
        2 ) FILE2=$OPTARG;;
        f ) FORMAT=$OPTARG;;
		h ) usage; exit 0;;
		* ) usage; exit 1;;
	esac
done
shift $(($OPTIND - 1)) 

function submit_job {
    qsub -V -pe orte 16 \
        -o ${JOB_NAME}${TAG}.o \
        -e ${JOB_NAME}${TAG}.e \
        -b y $SCRIPT_PATH $S3_PATH $EBS_NAME ;
}


case "$FORMAT" in
    bam ) EXTENSION=.bam;;
    fastq ) EXTENSION=.fastq.gz;;
esac

# Get full list of all files from S3 bucket for the specified group
FILE_LIST=`mktemp s3-seq-files.XXXXXXXX`
aws s3 ls ${BUCKET}/${SUBDIR} --recursive \
    | grep ${EXTENSION}$ \
    | awk '{print $4}' \
    > $FILE_LIST ;

NUM_FILES=$(wc -l ${FILE_LIST} | awk '{print $1}')
echo "$NUM_FILES files..."

# Function to pull out sample IDs from file paths
function get_id {
    while read line 
    do
        filename=${line##*/};
        fileid=${filename%%.*}
        echo $fileid;
    done < $1
}

# Get list of unique sample identifiers
NUM_IDS=$(get_id $FILE_LIST | wc -l | awk '{print $1}')
echo "$NUM_IDS ids..."

# Pull out all paired file paths
get_id ${FILE_LIST} | uniq | head -n 4 | while read ID
do
    FILE_PAIR=$(grep $ID $FILE_LIST)
    
    FILE1=${BUCKET}/$(echo $FILE_PAIR | awk '{print $1}')
    FILE2=${BUCKET}/$(echo $FILE_PAIR | awk '{print $2}')    
done

rm $FILE_LIST
