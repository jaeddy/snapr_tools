#!/bin/sh

CLUSTER_NAME=$1
EBS_NAME=$2

# Get list of cluster nodes
qhost | awk '{print $1}' | grep $CLUSTER_NAME > hostnames.txt

# Specify path to job script
SCRIPT_PATH=/${EBS_NAME}/snapr_tools/shell/mount_ssd.sh

# Mount SSD on each node
while read line; do
    
    echo "Mounting SSD on $line"
    qsub -l h=${line} $SCRIPT_PATH 

done < hostnames.txt

rm hostnames.txt
