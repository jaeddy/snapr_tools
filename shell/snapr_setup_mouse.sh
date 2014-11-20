#!/bin/sh

CLUSTER_NAME=$1
EBS_NAME=$2

qhost | awk '{print $1}' | grep $CLUSTER_NAME > hostnames.txt

# Build indices on each node
while read line; do
    
    echo "Building indices on $line"
    #./shell/build_indices_mouse.sh $EBS_NAME
    qsub -l h=${line} ./shell/build_indices_mouse.sh $EBS_NAME

done < hostnames.txt

rm hostnames.txt
