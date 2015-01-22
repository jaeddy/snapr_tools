#!/bin/bash

# This script will take a list of file paths in an S3 bucket (or query the 
# bucket directly to generate a list of all non-SNAPR-generated FASTQ or BAM
# files. Based on this list, calls to `s3_snapr.bash` are distributed across
# cluster nodes with `qsub`. Each job downloads data for an individual sample
# from S3, processes the file(s) with SNAPR, and uploads the results back to
# the original bucket.

######## Specify defaults & examples ##########################################

# Example inputs for S3 bucket subdirectory
BUCKET="s3://mayo-prelim-rnaseq"
# SUBDIR="AD_Samples"
# BUCKET="s3://ufl-u01-rnaseq"

# Default options for file format and alignment mode
MODE=paired
FORMAT=fastq
PAIR_LABEL="_R[1-2]_"

# Default options for SGE/qsub parameters
PROCS=16
MEM="230.0G"
NAME='default'
QUEUE=all.q
EMAIL="bob@bob.com"

# Default reference paths
GENOME="/resources/genome20/"
TRANSCRIPTOME="/resources/transcriptome20/"
ENSEMBL="/resources/Homo_sapiens.GRCh37.68.gtf"


######## Parse inputs #########################################################

function usage {
	echo "$0: [-m mem(3.8G,15.8G) [-p num_slots] [-q queue] [-N jobname] [-e email_address] [-g] -p prefix -1 file1.fastq -2 file2.fastq -o output_dir -b"
	echo
}

while getopts "b:L:m:n:s:N:f:h" ARG; do
	case "$ARG" in
	    b ) BUCKET=$OPTARG;;
	    L ) IN_LIST=$OPTARG; FILE_LIST=$IN_LIST;;
	    m ) MODE=$OPTARG;;
		n ) PROCS=$OPTARG;;
		s ) MEM=$OPTARG;;
		N ) NAME=$OPTARG;;
        f ) FORMAT=$OPTARG;;
		h ) usage; exit 0;;
		* ) usage; exit 1;;
	esac
done
shift $(($OPTIND - 1)) 

# function submit_job {
#     echo $("-S /bin/bash -V -cwd -j y" \ # basic options
#         "-N job.${PREFIX}" \ # job name
#         "-pe orte $PROCS" \ # number of processors
#         "-q $QUEUE" \ # submission queue
#         "-M $EMAIL -m beas" \ # notification email
#         "-l virtual_free=$MEM -l h_vmem=$MEM" \ # minimum memory
#         "-b y $SCRIPT_PATH $S3_PATH $EBS_NAME") ;
# }
# submit_job


######## Construct submission file with qsub options ##########################

QSUB_BASE=`mktemp qsub-settings.XXXXXXXX`
cat > $QSUB_BASE <<EOF
#!/bin/bash

### SGE settings #################################################

#$ -S /bin/bash
#$ -V

# Change to current working directory (otherwise starts in $HOME)
#$ -cwd

# Set the name of the job
#$ -N job.${NAME}

# Combine output and error files into single output file (y=yes, n=no)
#$ -j y

# Serial is used to keep all processors together
#$ -pe orte $PROCS

# Specify the queue to submit the job to (only one at this time)
#$ -q $QUEUE

# Specify my email address for notification
#$ -M $EMAIL

# Specify what events to notify me for
# 'b'=job begins, 'e'=job ends, 'a'=job aborts, 's'=job suspended, 'n'=no email
#$ -m beas

# Minimum amount free memory we want
#$ -l virtual_free=$MEM
#$ -l h_vmem=$MEM

EOF

echo "#$ $QSUBOPTS"


######## Assemble & prepare inputs for s3_snapr.bash ##########################

# Define more explicit extension formats & set reprocess flag if bam format
case "$FORMAT" in
    bam ) EXTENSION=.bam; REPROCESS="-r";;
    fastq ) EXTENSION=.fastq.gz;;
esac

# Search S3 bucket for files, if no input list is provided
if [ ! -e "$FILE_LIST" ];
then
    # Get full list of all files from S3 bucket for the specified group
    FILE_LIST=`mktemp s3-seq-files.XXXXXXXX`
    aws s3 ls ${BUCKET}/${SUBDIR} --recursive \
        | grep ${EXTENSION}$ \
        | grep -v .snap \
        | awk '{print $4}' \
        > $FILE_LIST ;
fi

NUM_FILES=`expr $(wc -l ${FILE_LIST} | awk '{print $1}') - 1`
echo "$NUM_FILES ${EXTENSION} files detected..."

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
NUM_IDS=`expr $(get_id ${FILE_LIST} | uniq | wc -l | awk '{print $1}') - 1`
echo "$NUM_IDS unique IDs detected..."


######## Assemble options for running s3_snapr.bash ###########################

JOB_SCRIPT=bash/s3_snapr.bash

OPTIONS="-m ${MODE} ${REPROCESS}"
if [ -z ${REPROCESS+x} ] && [ $MODE == paired ];
then
    OPTIONS="${OPTIONS} -l ${PAIR_LABEL}"
fi

REF_FILES="-g ${GENOME} -t ${TRANSCRIPTOME} -e ${ENSEMBL}"

######## Submit s3_snapr.bash jobs for each sample ############################

count=0
# Pull out all file paths matching unique sample IDs
get_id ${FILE_LIST} | uniq | head -n 4 | while read ID
do
    count=$(($count+1)) # counter for testing
    if [ $count -gt 1 ]
    then
        break
    fi
    
    FILE_MATCH=$(grep $ID $FILE_LIST)
    
    PATH1=${BUCKET}/$(echo $FILE_MATCH | awk '{print $1}')
    INPUT="-1 ${PATH1}"
    
    # Define second input file path only if extension format is FASTQ (i.e.,
    # the reprocess flag is undefined) and mode is paired
    if [ -z ${REPROCESS+x} ] && [ $MODE == paired ];
    then
        PATH2=${BUCKET}/$(echo $FILE_MATCH | awk '{print $2}')
        INPUT="${INPUT} -2 ${PATH2}"
    fi
    
    echo "Submitting the following job:"
    echo "$JOB_SCRIPT $OPTIONS $INPUT $REF_FILES"
    echo
    $JOB_SCRIPT $OPTIONS $INPUT $REF_FILES
        
    JOB_SETTINGS=`mktemp qsub-job.XXXXXXXX`
    cat > $JOB_SETTINGS <<EOF

### Job settings ###################################################

$JOB_SCRIPT -m ${MODE} ${PATH1} ${PATH2} \
    -g $GENOME \
    -t $TRANSCRIPTOME \
    -e $ENSEMBL
    
EOF
    
    SUBMIT_FILE=`mktemp qsub-submit.XXXXXXXX`
    cat $QSUB_BASE $JOB_SETTINGS > $SUBMIT_FILE
    
#     cat $SUBMIT_FILE
    
    rm $JOB_SETTINGS
    rm $SUBMIT_FILE
done

rm $QSUB_BASE
if [ ! -e "$IN_LIST" ];
then
    rm $FILE_LIST
fi

