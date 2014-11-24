#!/bin/sh

CLUSTER_NAME=$1
EBS_NAME=$2

qhost | awk '{print $1}' | grep $CLUSTER_NAME > hostnames.txt

# Specify path to job script
SCRIPT_PATH=/${EBS_NAME}/snapr_tools/shell/build_indices_mouse.sh

# Build indices on each node
while read line; do

    echo "Building indices on $line"
    #./shell/build_indices.sh $EBS_NAME
    qsub -V -l h=${line} $SCRIPT_PATH $EBS_NAME

done < hostnames.txt

rm hostnames.txt
