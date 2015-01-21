#!/bin/bash

S3_PATH=$1

GENOME=/resources/genome20
TRANSCRIPTOME_DIR=/resources/transcriptome20
ENSEMBL=/resources/Homo_sapiens.GRCh38.77.gtf

MODE=single
PAIRTAG="_R[1-2]_"

while getopts "sp1:2:g:t:e:h" ARG; do
	case "$ARG" in
	    s ) MODE=single;;
	    p ) MODE=paired;;
	    1 ) PATH1=$OPTARG;;
	    2 ) PATH2=$OPTARG;;
		g ) GENOME=$OPTARG;;
		t ) TRANSCRIPTOME=$OPTARG;;
		e ) ENSEMBL=$OPTARG;;
		h ) usage; exit 0;;
		* ) usage; exit 1;;
	esac
done
shift $(($OPTIND - 1))

echo "$MODE $PATH1"

# Function to pull out sample IDs from file paths
function get_id {
    filename=${line##*/};
    fileid=${filename%%.*}
    echo $fileid;
    < $1
}

# Parse S3 file path
S3_DIR=$(dirname $PATH1)
FILE1=${PATH1##*/}
PREFIX=${FILE1%.}
echo $PREFIX

if [ $MODE == paired ]
then
    PREFIX=$(echo $PREFIX | awk '{gsub("_R[1-2]_", "_")}1')
fi

echo $PREFIX
    
# Create temporary directory for input files
# TMP_DIR=/results/${SAMPLE}_tmp/
# if [ ! -e "$TMP_DIR" ]; then
#     mkdir "$TMP_DIR"
# fi


# Download S3 file
echo "Copying $PATH1 to $FILE1"

# aws s3 cp \
#     $S3_PATH \
#     $INPUT_FILE ;


# Define SNAPR output file
OUTPUT_FILE=${TMP_DIR}${PREFIX}.snap.bam

# Run SNAPR
# time snapr $MODE \
#     $GENOME \
#     $TRANSCRIPTOME \
#     $ENSEMBLE \
#     $INPUT_FILE \
#     -o $OUTPUT_FILE \
#     -M \
#     -rg $PREFIX \
#     -so \
#     -ku ;
# 
# Remove original file
# rm $INPUT_FILE
# 
# Copy files to S3
# aws s3 cp \
#     $TMP_DIR \
#     $S3_DIR/snapr/ \
#     --recursive ;
# 
# Remove temporary directory
# rm -rf $TMP_DIR
