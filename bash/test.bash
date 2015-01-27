#!/bin/bash

MODE=paired
PAIR_LABEL="_[1-2]_"

# FILE1="some_rnaseq_file_1_foo.fastq"
# FILE2="some_rnaseq_file_2_foo.fastq"

FILE1="some_rnaseq_file_foo.bam"
REPROCESS=1

testfile=`mktemp testfile.XXX`

cat > $testfile <<EOF
$FILE1
EOF

cat $testfile

function get_id {
    while read line
    do
        filename=${line##*/};
        handle=$(echo $filename \
            | awk -v tag="(${PAIR_LABEL})+.*" '{gsub(tag, "")}1')
        echo $handle;
    done < $1
}

# get_id $testfile

get_id $testfile | uniq | while read line; do
    FILE_MATCH=$(grep $line $testfile)

    PATH1=$(echo $FILE_MATCH | awk '{print $1}')
    INPUT="-1 ${PATH1}"
    echo $INPUT

    # Define second input file path only if extension format is FASTQ (i.e.,
    # the reprocess flag is undefined) and mode is paired
    if [ -z ${REPROCESS+x} ] && [ $MODE == paired ];
        then
        PATH2=$(echo $FILE_MATCH | awk '{print $2}')
        INPUT="${INPUT} -2 ${PATH2}"
        echo $INPUT
    fi
done


rm $testfile

# filename=${FILE1##*/};
# echo $filename
#
# fileid=${filename%%.*}
# echo $fileid
#
# FILE_HANDLE=echo $FILE1 | awk -v tag="$PAIR_LABEL" '{gsub(tag, "_")}1'
