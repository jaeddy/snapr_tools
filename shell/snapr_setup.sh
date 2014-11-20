#!/bin/sh

CLUSTER_NAME=$1

head qhost.txt | awk '{print $1}' | grep $CLUSTER_NAME > hostnames.txt

# Mount SSD on each node
while read line; do
    
    echo $line
    # qsub -l h=${line} ./prep_node.sh 

done < hostnames.txt

rm hostnames.txt