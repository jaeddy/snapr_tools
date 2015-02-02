#!/bin/bash

# This script is used to check whether all source files were successfully copied # from the local machine to an S3 bucket.

######## Specify inputs #######################################################

BUCKET=$1
SUBDIR=$2
IN_LIST=$3

# Get full list of all files from S3 bucket for the specified group
FILE_LIST=`mktemp s3-seq-files.XXXXXXXX`
aws s3 ls ${BUCKET}/${SUBDIR} --recursive \
	| grep -e ".fastq" -e ".bam$" \
	| grep -v .snap \
	| awk '{print $4}' \
	> $FILE_LIST ;

# Pull out list of uploaded source files
echo "$(wc -l $FILE_LIST | awk '{print $1}') S3 files detected..."

# Count list of local files
echo "$(wc -l $IN_LIST | awk '{print $1}') local files..."


function strip_head {
	while read line; do
		filename=${line#*/};
		handle=$(echo $filename \
			| awk '{gsub("\r", "\n")}1')
		echo $handle;
	done < $1
}


# Find any local files not present on S3
MISSED=`mktemp missed-uploads.XXXXXXXX`
comm -23 <(strip_head $IN_LIST | sort) \
	<(strip_head $FILE_LIST | sort) > $MISSED

NUM_MISSED=$(wc -l $MISSED | awk '{print $1}')
if [ $NUM_MISSED -gt 0 ]; then
	echo "${NUM_MISSED} files missed."

	OUT_FILE=${BUCKET}_${SUBDIR}_noupload.txt
	OUT_FILE=${OUT_FILE##*/};

	echo "Saving list to ${OUT_FILE}..."
	echo $OUT_FILE
	# grep -f $MISSED $IN_LIST > $OUT_FILE
	awk -v head="${SUBDIR}/" '$0=head$0' $MISSED > $OUT_FILE
else
	echo "No files missed."
fi

rm $FILE_LIST
rm $MISSED
