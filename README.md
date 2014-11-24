This is a set of simple tools I'm putting together to facilitate running SNAPR on an AWS EC2 cluster instance. Most of the scripts could be improved with better argument handling and additional documentation. Also, I imagine some parts of the current setup will change as we become less dependent (hopefully) on EBS volumes.

### Basic infrastructure

The code currently assumes you have an attached EBS volume, which includes all required binaries and reference files for running `snapr`. This volume should be mounted at the top level, such that `ls` of the EBS volume called `snapr-volume` returns the following:

```
user@snapr-cluster-master:~# ls /snapr-volume/
assemblies  bash  bin  indices  jobs  mouse_indices  processMasonCounts.py  transcriptome.fa
```

The name of the cluster, in this case `snapr-cluster` is also used below to set up the parallel computing environment with Sun Grid Engine.

##### Cluster details

> **AMI:** ami-80bedfb0  
> **Volume:** vol-4c97994d  
> **Instance type:** r3.4xlarge  
> **Availability zone:** us-west-2b


### Getting started

If not already present in the `snapr-volume` directory, `cd` and clone this repository with the following command:

```
user@snapr-cluster-master:/snapr-volume# git clone https://github.com/jaeddy/snapr_tools
```

Go ahead and `cd` into the `/snapr-volume/snapr_tools/` directory before running any of the scripts below.


### Example use case: reprocessing BAM files stored on S3

This was the primary task for which most of the scripts here were designed. I previously created an S3 bucket and uploaded a large set of BAM files from RNAseq experiments in both human and mouse samples. The objectives of the following steps were as follows:

1. Set up environment for running SNAPR on EC2 cluster  
2. Download (in parallel) individual BAM files from specified S3 bucket/directory  
3. Run SNAPR on each BAM file  
4. Upload reprocessed SNAPR BAM files and other outputs to S3

#### Setting up SNAPR environment

This first script will ensure that solid-state drives (SSDs) are properly mounted on all nodes by running `mount_ssd.sh` in parallel with `qsub`:

```
user@snapr-cluster-master:/snapr/snapr_tools# shell/ssd_setup.sh snapr-cluster
```
Note that the cluster name is provided as the single input. Currently, this script will also install the AWS Command Line Interface on all nodes, as `awscli` isn't part of the AMI yet.

Next, we need to copy all reference files to individual nodes and build genome/transcriptome indices with `snapr`. This is done with the following script, which calls `build_indices.ssh`:

```
user@snapr-cluster-master:/snapr/snapr_tools# shell/snapr_setup.sh snapr-cluster snapr-volume
```

In this case, there are two inputs: cluster name and volume name.


#### S3 data transfer and processing

To run `snapr` on the target set of BAM files on S3, use the following script, which submits an individual `s3_snapr.sh` job for each file.

```
user@snapr-cluster-master:/snapr/snapr_tools# shell/submit_s3_snapr.sh [ S3_BUCKET ] [ GROUP ] snapr-volume
```

The `S3_BUCKET` input should be a valid S3 address (e.g., s3://bam-file-bucket), and `GROUP` should be the name of any top-level directories containing groups of samples. For example:

```
user@snapr-cluster-master:/snapr/snapr_tools# aws s3 ls s3://bam-file-bucket
                           PRE Case_Samples/
                           PRE Control_Samples/
```

In this case, an appropriate input for `GROUP` would be `Case_Samples`. The final command would be structured as follows:

```
user@snapr-cluster-master:/snapr/snapr_tools# shell/submit_s3_snapr.sh s3://bam-file-bucket Control_Samples snapr-volume
```

This step will take care of all data transfer from and to S3 as well as generation of `snapr` alignment results.


### Notes/warnings

+ I'm still working on setting up a set of scripts that will work specifically with mouse data (with the goal of eventually just adding a flag to the above scripts).  
+ `snapr` is run with the default options; changing these would currently require modifying the `s3_snapr.sh` code directly.
+ I also started working on a similar set of scripts to download BAM files and directly calculate gene counts using `htseq-count`; however, I gave up on this (for now) due to issues with BAM file formats.