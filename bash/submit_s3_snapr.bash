#!/bin/bash

# BUCKET="s3://mayo-prelim-rnaseq"
# SUBDIR="AD_Samples"
BUCKET="s3://ufl-u01-rnaseq"

PROCS=16
MEM="230.0G"
NAME='default'
QUEUE=all.q
EMAIL="bob@bob.com"

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
		n ) PROCS=$OPTARG;;
		s ) MEM=$OPTARG;;
		N ) NAME=$OPTARG;;
        1 ) FILE1=$OPTARG;;
        2 ) FILE2=$OPTARG;;
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

FILE=`mktemp snap-rna.XXXXXXXX`

cat > $FILE <<EOF
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
# cat $FILE

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
