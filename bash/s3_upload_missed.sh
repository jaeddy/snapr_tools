#!/bin/bash

# This script is used to upload any source files that were not successfully
# copied from the local machine to an S3 bucket (see output of
# s3_upload_check.sh).

######## Specify inputs #######################################################

BUCKET=$1
UP_LIST=$2

# Upload all files in list to S3 bucket
while read file; do
	aws s3 cp --dryrun \
		$file $BUCKET/$file
	done < $2
