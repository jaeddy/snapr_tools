#!/bin/sh

EBS_NAME=/$1/

# Copy stderr outputs from SGE
cp /root/*.e ${EBS_NAME}snapr_tools/sge_logs

# Copy stdout outputs from SGE
cp /root/*.o ${EBS_NAME}snapr_tools/sge_logs
