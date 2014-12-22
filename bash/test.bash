#!/bin/bash

PROCS=16
MEM="230.0G"
QUEUE=all.q
GENONLY=0
JOBNAME="snap-rna"
EMAIL="bob@bob.com"
NODE="node001"
FILE1='file1.fastq'
FILE2='file2.fastq'
PREFIX='default'
OUTPUT='/results'
SAVE_BAM=0

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
        1 ) FILE1=$OPTARG;;
        2 ) FILE2=$OPTARG;;
        p ) PREFIX=$OPTARG;;
        o ) OUTPUT=$OPTARG;;
        b ) SAVE_BAM=1;;
		h ) usage; exit 0;;
		* ) usage; exit 1;;
	esac
done
shift $(($OPTIND - 1)) 

APP="/snap/bin/snap/snap-rna"
OPTIONS="paired /snap/Genomes/GRCh37/snap/genome20/ /snap/Genomes/GRCh37/snap/transcriptome20/ /snap/Genomes/GRCh37/gtf/Homo_sapiens.GRCh37.68.gtf ${FILE1} ${FILE2} -o ${PREFIX}.snap.bam -t $PROCS -M -c 2 -d 4 -s 0 20000 -so -rg $PREFIX"

echo $OPTIONS

GENOME="/snap/Genomes/GRCh37/fasta/Homo_sapiens.GRCh37.68.genome.fa"
