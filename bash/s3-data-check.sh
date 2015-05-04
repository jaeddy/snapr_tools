#!/bin/bash

PID=`echo $$`
S3_OUT_DIR=$1
LOCAL_DIR=$2
aws s3 ls $S3_OUT_DIR | awk '{print $3}' | sort > /tmp/s3-output$PID
ls -la $LOCAL_DIR | awk '{print $5}' | tail -n +4 | sort > /tmp/fs-output$PID
echo `diff /tmp/s3-output$PID /tmp/fs-output$PID`
