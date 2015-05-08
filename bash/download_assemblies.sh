#!/bin/bash

echo "Beginning to download assemblies from S3"

FASTA_SRC=$1
GTF_SRC=$2

PID=$$
NUM_RETRIES=0
touch /tmp/s3-local-file-diff$PID
echo "empyline" > /tmp/s3-local-file-diff$PID
while [ -s /tmp/s3-local-file-diff$PID ] || [ $NUM_RETRIES < $MAX_RETRIES]
do
    aws s3 cp $FASTA_SRC /resources/assemblies/ref-genome.fa ;
    aws s3 ls $FASTA_SRC | cut -d " " -f 3  | sort > /tmp/s3-output$PID
    ls -la /resources/assemblies/ref-genome.fa | cut -d " " -f 5 | sort > /tmp/fs-output$PID
    diff /tmp/s3-output$PID /tmp/fs-output$PID  > /tmp/s3-local-file-diff$PID

    if [ -s /tmp/s3-local-file-diff$PID ]; then
        echo "There was an unknown error in downloading the FASTA file from S3. Retrying. Trial number $NUM_RETRIES"
    fi
    let NUM_RETRIES++
done

NUM_RETRIES=0
touch /tmp/s3-local-file-diff$PID
echo "emptyline" > /tmp/s3-local-file-diff$PID
while [ -s /tmp/s3-local-file-diff$PID ] || [ $NUM_RETRIES < $MAX_RETRIES]
do
    aws s3 cp $GTF_SRC /resources/assemblies/ref-transcriptome.gtf ;
    aws s3 ls $GTF_SRC | cut -d " " -f 3  | sort > /tmp/s3-output$PID
    ls -la /resources/assemblies/ref-transcriptome.gtf | cut -d " " -f 5 | sort > /tmp/fs-output$PID
    diff /tmp/s3-output$PID /tmp/fs-output$PID  > /tmp/s3-local-file-diff$PID

    let NUM_RETRIES++
    if [ -s /tmp/s3-local-file-diff$PID ]; then
        echo "There was an unknown error in downloading the GTF file from S3. Retrying. Trial number $NUM_RETRIES"
    fi
done

echo "Completed downloading assemblies from S3"
