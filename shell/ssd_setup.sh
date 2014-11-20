#!/bin/sh

CLUSTER_NAME=$1

qhost | awk '{print $1}' | grep $CLUSTER_NAME > hostnames.txt

# Mount SSD on each node
while read line; do
    
    echo "Mounting SSD on $line"
    qsub -l h=${line} ./shell/mount_ssd.sh 

done < hostnames.txt

rm hostnames.txt
