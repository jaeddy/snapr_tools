#!/bin/bash

# This script will take a list of file paths in an S3 bucket (or query the
# bucket directly to generate a list of all non-SNAPR-generated FASTQ or BAM
# files. Based on this list, calls to `s3_snapr.bash` are distributed across
# cluster nodes with `qsub`. Each job downloads data for an individual sample
# from S3, processes the file(s) with SNAPR, and uploads the results back to
# the original bucket.

######## Specify defaults & examples ##########################################

# Example inputs for S3 bucket subdirectory
# BUCKET="s3://mayo-prelim-rnaseq"
# SUBDIR="AD_Samples"
# BUCKET="s3://ufl-u01-rnaseq"
# BUCKET="s3://rna-editing-exdata"
# SUBDIR="chr8"

# Default options for file format and alignment mode
MODE=paired
FORMAT=fastq
PAIR_LABEL="_R[1-2]_"

# Default options for SGE/qsub parameters
PROCS=16
MEM="60.0G"
NAME="s3_snapr"
QUEUE=all.q
EMAIL="bob@bob.com"

# Default reference paths
GENOME="/resources/genome/"
TRANSCRIPTOME="/resources/transcriptome/"
GTF_FILE="/resources/assemblies/ref-transcriptome.gtf"

# Default behavior for script
KEEP=0 # 0: upload outputs to S3 vs. 1: keep on local machine
DISPONLY=0 # 1: print job settings vs. 0: submit with qsub

######## Parse inputs #########################################################

function usage {
    echo "$0: -b s3_bucket [-s subdir] [-L file_list] [-m mode (paired/single)] [-f format (bam/fastq)] [-l pair_file_label] [-g genome_index] [-t transcriptome_index] [-x ref_transcriptome] [-p num_procs] [-q queue] [-N jobname] [-M mem(3.8G,15.8G)] [-E email_address] [-k] [-d]"
    echo
}

while getopts "b:s:L:m:f:l:g:t:e:p:q:N:E:kdh" ARG; do
    case "$ARG" in
        b ) BUCKET=$OPTARG;;
        s ) SUBDIR=$OPTARG;;
        L ) IN_LIST=$OPTARG; FILE_LIST=$IN_LIST;;
        m ) MODE=$OPTARG;;
        f ) FORMAT=$OPTARG;;
        l ) PAIR_LABEL=$OPTARG;;
        g ) GENOME=$OPTARG;;
        t ) TRANSCRIPTOME=$OPTARG;;
        x ) GTF_FILE=$OPTARG;;
        p ) PROCS=$OPTARG;;
        q ) QUEUE=$OPTARG;;
        N ) NAME=$OPTARG;;
        M ) MEM=$OPTARG;;
        E ) EMAIL=$OPTARG;;
        k ) KEEP=1;;
        d ) DISPONLY=1;;
        h ) usage; exit 0;;
        * ) usage; exit 1;;
    esac
done
shift $(($OPTIND - 1))


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


######## Assemble & prepare inputs for s3_snapr.bash ##########################

# Search S3 bucket for files, if no input list is provided
if [ ! -e "$FILE_LIST" ]; then
    # Get full list of all files from S3 bucket for the specified group
    FILE_LIST=`mktemp s3-seq-files.XXXXXXXX`
    aws s3 ls ${BUCKET}/${SUBDIR} --recursive \
        | grep ${FORMAT} \
        | grep -v .snap \
        | awk '{print $4}' \
        > $FILE_LIST ;
fi

NUM_FILES=`expr $(wc -l ${FILE_LIST} | awk '{print $1}')`
echo "$NUM_FILES ${FORMAT} files detected..."

# Set reprocess flag if bam format
if [ $FORMAT = bam ]; then
    REPROCESS="-r"
    echo "Files will be reprocessed with SNAPR."
    echo
fi

# Function to pull out sample IDs from file paths
function get_handle {
    while read line; do
        filename=${line##*/};
        handle=$(echo $filename \
        | awk -v tag="(${PAIR_LABEL})+.*" '{gsub(tag, "")}1')
        echo $handle;
    done < $1
}

# Get list of unique sample handles
NUM_IDS=`expr $(get_handle ${FILE_LIST} | uniq | wc -l | awk '{print $1}')`
echo "$NUM_IDS unique sample(s) detected..."
echo


######## Assemble options for running s3_snapr.bash ###########################

JOB_SCRIPT=bash/s3_snapr.sh

OPTIONS="-m ${MODE} ${REPROCESS}"
if [ -z ${REPROCESS+x} ] && [ $MODE == paired ]; then
    OPTIONS="${OPTIONS} -l ${PAIR_LABEL}"
fi

if [ ${KEEP} == 1 ]; then
    OPTIONS="${OPTIONS} -k"
fi

REF_FILES="-g ${GENOME} -t ${TRANSCRIPTOME} -x ${GTF_FILE}"


######## Submit s3_snapr.bash jobs for each sample ############################

count=0
# Pull out all file paths matching unique sample IDs
get_handle ${FILE_LIST} | uniq | while read HANDLE; do
    count=$(($count+1)) # counter for displaying preview (and testing)
    if [ $count -gt 1 ] && [ $DISPONLY == 1 ]; then
        break
    fi

    FILE_MATCH=$(grep $HANDLE $FILE_LIST)

    PATH1=${BUCKET}/$(echo $FILE_MATCH | awk '{print $1}')
    INPUT="-d ${BUCKET}/${SUBDIR} -1 ${PATH1}"
    if [ -z ${SUBDIR+x} ]; then
        INPUT="-d ${BUCKET} -1 ${PATH1}"
    fi

    # Define second input file path only if extension format is FASTQ (i.e.,
    # the reprocess flag is undefined) and mode is paired
    if [ -z ${REPROCESS+x} ] && [ $MODE == paired ]; then
        PATH2=${BUCKET}/$(echo $FILE_MATCH | awk '{print $2}')
        INPUT="${INPUT} -2 ${PATH2}"
    fi

    JOB_SETTINGS=`mktemp qsub-job.XXXXXXXX`
    cat > $JOB_SETTINGS <<EOF

### Job settings ###################################################

time $JOB_SCRIPT $OPTIONS $INPUT $REF_FILES

EOF

    SUBMIT_FILE=`mktemp qsub-submit.XXXXXXXX`
    cat $QSUB_BASE $JOB_SETTINGS > $SUBMIT_FILE

    if [ $DISPONLY == 1 ]; then
        echo "#$ QSUBOPTS"
        cat $SUBMIT_FILE
    else
        echo "Submitting the following job:"
        echo "$JOB_SCRIPT $OPTIONS $INPUT $REF_FILES"
        echo
        qsub $QSUBOPTS < $SUBMIT_FILE
    fi

    rm $JOB_SETTINGS
    rm $SUBMIT_FILE
done

rm $QSUB_BASE
if [ ! -e "$IN_LIST" ]; then
    rm $FILE_LIST
fi
