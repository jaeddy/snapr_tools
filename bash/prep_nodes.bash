#!/bin/bash

# This script perform the following tasks on each node: 1) mount SSD; 2) create
# standard directories used by downstream code; 3) copy and rename reference 
# files to resources directory.

######## Specify defaults & examples ##########################################

# Default options for S3-stored references files
S3_BUCKET="s3://snapr-ref-assemblies"
SPECIES="human"
HUMAN_FASTA="Homo_sapiens.GRCh38.dna.SORTED.fa"
HUMAN_GTF="Homo_sapiens.GRCh38.77.gtf"
MOUSE_FASTA="Mus_musculus.GRCm38.75.dna.SORTED.fa"
MOUSE_GTF="Mus_musculus.GRCm38.75.gtf"

# Default for assuming input ref file is local or on S3
LOCAL=0

# Default options for SGE/qsub parameters
NAME="snapr_node_prep"
QUEUE=all.q
EMAIL="bob@bob.com"


######## Parse inputs #########################################################

function usage {
	echo "$0: [-s species] [-g fasta_file] [-x gtf_file] [-L] cluster_name"
	echo
}

while getopts "s:g:x:Lh" ARG; do
	case "$ARG" in
	    s ) SPECIES=$OPTARG;;
	    g ) FASTA_FILE=$OPTARG;;
	    x ) GTF_FILE=$OPTARG;;
	    L ) LOCAL=1;;
		h ) usage; exit 0;;
		* ) usage; exit 1;;
	esac
done
shift $(($OPTIND - 1)) 


######## Specify human or mouse specific options ##############################

# Default reference paths
case "$SPECIES" in
    human )
        FASTA_SRC="${S3_BUCKET}/${SPECIES}/${HUMAN_FASTA}"
        GTF_SRC="${S3_BUCKET}/${SPECIES}/${HUMAN_GTF}"
        ;;
    mouse )
        FASTA_SRC="${S3_BUCKET}/${SPECIES}/${MOUSE_FASTA}"
        GTF_SRC="${S3_BUCKET}/${SPECIES}/${MOUSE_GTF}"
        ;;
esac


######## Construct submission file with qsub & job settings ###################

HOST_NAME=$(hostname)
CLUSTER_NAME=${HOST_NAME%-*}

qhost | awk '{print $1}' | grep $CLUSTER_NAME | while read NODE; do

SUBMIT_FILE=`mktemp node-prep.XXXXXXXX`

cat > $SUBMIT_FILE <<EOF
#!/bin/bash

### SGE settings #################################################

#$ -S /bin/bash
#$ -V

# Change to current working directory (otherwise starts in $HOME)
#$ -cwd

# Set the name of the job
#$ -N job.${PREFIX}

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

# Mount the SS hard drive

sudo mkfs.ext4 /dev/xvdaa
sudo mkdir -m 000 /mnt # isnt required if /mnt exists.
echo "/dev/xvdaa /mnt auto noatime 0 0" | sudo tee -a /etc/fstab
sudo mount /mnt

# Create standard directories & symlinks

mkdir /mnt/resources
ln -s /mnt/resources /resources

mkdir /mnt/data
ln -s /mnt/data /data

mkdir /mnt/results
ln -s /mnt/results /results

# Install AWS CLI (this shouldn't be necessary once added to AMI)

pip install awscli

# Create resource directories

mkdir /resources/assemblies
mkdir /resources/genome
mkdir /resources/transcriptome

# Copy and rename assembly files from S3

if [ $LOCAL == 0 ];
then
    aws s3 cp $FASTA_SRC resources/genome/ref-genome.fa ;

    aws s3 cp $GTF_SRC resources/transcriptome/ref-transcriptome.gtf ;
else
    cp $FASTA_FILE /resources/genome/ref-genome.fa ;
    cp $GTF_FILE /resources/transcriptome/ref-transcriptome.gtf
fi

EOF

qsub $QSUBOPTS < $SUBMIT_FILE
rm $SUBMIT_FILE

done

