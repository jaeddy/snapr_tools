#!/bin/bash

# This script perform the following tasks on each node: 1) mount SSD; 2) create
# standard directories used by downstream code; 3) copy and rename reference 
# files to resources directory.

######## Specify defaults & examples ##########################################

# Default reference paths
GENOME="/resources/genome/"
TRANSCRIPTOME="/resources/transcriptome/"
FASTA_FILE="/resources/assemblies/ref-genome.fa"
GTF_FILE="/resources/assemblies/ref-transcriptome.gtf"

# Default options for SGE/qsub parameters
NAME="snapr_indices"
QUEUE=all.q
EMAIL="bob@bob.com"

# Default behavior for script (print job settings vs. submit with qsub)
DISPONLY=0

# Define snapr executable
SNAPR_EXEC="snapr"


######## Parse inputs #########################################################

function usage {
	echo "$0: [-q queue] [-N jobname] [-M mem(3.8G,15.8G)] [-E email_address] [-d]"
	echo
}

while getopts "g:x:Ldh" ARG; do
	case "$ARG" in
	    d ) DISPONLY=1;;
	    q ) QUEUE=$OPTARG;;
		N ) NAME=$OPTARG;;
		E ) EMAIL=$OPTARG;;
		h ) usage; exit 0;;
		* ) usage; exit 1;;
	esac
done
shift $(($OPTIND - 1)) 


######## Construct submission file with qsub & job settings ###################

HOST_NAME=$(hostname)
CLUSTER_NAME=${HOST_NAME%-*}

qhost | awk '{print $1}' | grep $CLUSTER_NAME | while read NODE; do

SUBMIT_FILE=`mktemp index-build.XXXXXXXX`

cat > $SUBMIT_FILE <<EOF
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

# Specify the current node
#$ -l h=${NODE}

# Specify my email address for notification
#$ -M $EMAIL

# Specify what events to notify me for
# 'b'=job begins, 'e'=job ends, 'a'=job aborts, 's'=job suspended, 'n'=no email
#$ -m beas


### Job settings ###################################################

# Build genome index
$SNAPR_EXEC index $FASTA_FILE $GENOME -bSpace ;

# Build transcriptome index
$SNAPR_EXEC transcriptome $GTF_FILE $FASTA_FILE $TRANSCRIPTOME -bSpace ;

EOF

if [ $DISPONLY == 1 ]; 
then
    echo "#$ QSUBOPTS"
    cat $SUBMIT_FILE
else    
    echo "Building indices on node $NODE"
    echo
    qsub $QSUBOPTS < $SUBMIT_FILE
fi

rm $SUBMIT_FILE

done

