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
# 
# function usage {
# 	echo "$0: [-m mem(3.8G,15.8G) [-p num_slots] [-q queue] [-N jobname] [-e email_address] [-g] -p prefix -1 file1.fastq -2 file2.fastq -o output_dir -b"
# 	echo
# }
# 
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


echo $FORMAT

case "$FORMAT" in
    bam ) EXTENSION=.bam;;
    fastq ) EXTENSION=.fastq.gz;;
esac

echo $EXTENSION

# Get full list of all BAM files from S3 bucket for the specified group
FILE_LIST=`mktemp s3-seq-files.XXXXXXXX`

aws s3 ls ${BUCKET}/${SUBDIR} --recursive \
    | grep ${EXTENSION}$ \
    | awk '{print $4}' \
    > $FILE_LIST ;

NUM_FILES=$(wc -l ${FILE_LIST} | awk '{print $1}')
echo "$NUM_FILES files..."

function get_id {
    while read line 
    do
        filename=${line##*/};
        fileid=${filename%%.*}
        echo $fileid;
    done < $1
}

# Get list of unique sample identifiers
ID_LIST=`mktemp s3-seq-ids.XXXXXXXX`

get_id ${FILE_LIST} | uniq > $ID_LIST

NUM_IDS=$(wc -l ${ID_LIST} | awk '{print $1}')
echo "$NUM_IDS ids..."

# rm $FILE_LIST
