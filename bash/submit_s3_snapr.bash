#!/bin/bash

BUCKET="s3://bucket-name"
GROUP="directory"
EBS_NAME="snapr"

PROCS=16
MEM="230.0G"
QUEUE=all.q
GENONLY=0
JOBNAME="snap-rna"
EMAIL="bob@bob.com"
NODE="node001"
PREFIX='default'
OUTPUT='/results'

function usage {
	echo "$0: [-m mem(3.8G,15.8G) [-p num_slots] [-q queue] [-N jobname] [-e email_address] [-g] -p prefix -1 file1.fastq -2 file2.fastq -o output_dir -b"
	echo
}

while getopts "p:n:q:m:N:e:o:1:2:gh" ARG; do
	case "$ARG" in
		q ) QUEUE=$OPTARG;;
		m ) MEM=$OPTARG;;
		N ) JOBNAME=$OPTARG;;
		e ) EMAIL=$OPTARG;;
		g ) GENONLY=1;;
    	r ) OPTIONS=$OPTARG;;
        p ) PREFIX=$OPTARG;;
        o ) OUTPUT=$OPTARG;;
        b ) SAVE_BAM=1;;
		h ) usage; exit 0;;
		* ) usage; exit 1;;
	esac
done
shift $(($OPTIND - 1)) 


# Get full list of all BAM files from S3 bucket for the specified group
# aws s3 ls ${BUCKET}/${GROUP} --recursive \
#     | grep .bam$ \
#     | awk '{print $4}' \
#     > ${GROUP}_bam_files.txt ;

NUM_FILES=$(wc -l ${GROUP}_bam_files.txt | awk '{print $1}')
echo "$NUM_FILES files detected..."


# Specify path to job script
SCRIPT_PATH=/${EBS_NAME}/snapr_tools/shell/s3_snapr.sh

for FILE_NUM in $(seq 1 $NUM_FILES); do
    
    FILE=$(awk -v r=$FILE_NUM 'NR==r{print;exit}' ${GROUP}_bam_files.txt)
    S3_PATH=$BUCKET/$FILE
    JOB_NAME=$(basename $S3_PATH)
    echo "Running SNAPR on file $JOB_NAME"

#     qsub -V -pe orte 16 \
#         -o ${JOB_NAME}${TAG}.o \
#         -e ${JOB_NAME}${TAG}.e \
#         -b y $SCRIPT_PATH $S3_PATH $EBS_NAME ;
    
done


