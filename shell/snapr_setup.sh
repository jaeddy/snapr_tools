#!/bin/sh

CLUSTER_NAME=$1
EBS_NAME=$2

# Get list of cluster nodes
qhost | awk '{print $1}' | grep $CLUSTER_NAME > hostnames.txt

# Specify path to job script
SCRIPT_PATH=/${EBS_NAME}/snapr_tools/shell/build_indices.sh

# Build indices on each node
while read line; do
    
    echo "Building indices on $line"
    qsub -V -l h=${line} $SCRIPT_PATH $EBS_NAME

done < hostnames.txt

rm hostnames.txt
