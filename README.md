This is a set of simple tools I'm putting together to facilitate running SNAPR on an AWS EC2 cluster instance. The main tasks performed by the scripts below are as follows:

1. Set up environment for running SNAPR on EC2 cluster  
2. Download (in parallel) individual FASTQ/BAM files from specified S3 bucket/directory  
3. Run SNAPR on each FASTQ/BAM file  
4. Upload reprocessed SNAPR BAM files and other outputs to S3

*Note: all scripts under the* `/shell` *directory are deprecated and will be removed soon.*

## Basic infrastructure

The code is designed to run on an AMI that includes all required binaries for running `snapr` or interacting with Amazon S3. Reference files, by default, can be accessed from the S3 bucket s3://snapr-ref-assemblies; these files can also be provided in the local (EC2) environemnt.

Steps in the SNAPR pipeline - including node setup, index building, and alignment - are distributed across cluster nodes using the Sun Grid Engine scheduling system.

##### *Cluster details*

> **AMI:** ami-57782067  
> **Instance type:** r3.4xlarge  
> **Availability zone:** us-west-2b


## Getting started

If not already present on the cluster, `cd` to a directory under `/home/` and clone this repository with the following command:

```
user@master:/home# git clone https://github.com/jaeddy/snapr_tools
```

Go ahead and `cd` into the `/home/snapr_tools/` directory before running any of the scripts below.

## Setting up SNAPR environment

This first script will ensure that solid-state drives (SSDs) are properly mounted on all nodes, set up the expected directory for downstream scripts, install `awscli`, and copy reference files from S3:

```
user@master:/home/snapr_tools# bash/prep_nodes.sh
```

##### *Setup options*

By default, running this script with no additional inputs will prepare all nodes for `snapr` alignment with the following human reference files:

* **Genome assembly:** Homo_sapiens.GRCh38.dna.SORTED.fa  
* **Transcriptome assembly:** Homo_sapiens.GRCh38.77.gtf  

Additional options for each can be specified using the following arguments: `-g fasta_file` and `-x gtf_file` (to see a list of available reference files, use `aws s3 ls s3://snapr-ref-assemblies`). Note: if you want to copy files for aligning mouse RNA-seq, use the `-s mouse` argument to specify the species. You can also provide paths to local reference files by adding the `-L` flag.

Other input arguments to `prep_nodes.sh` can be used to specify `qsub` submission settings.

## Building indices

Before `snapr` can be used for alignment, use the following command to build genome and transcriptome indices on each node:

```
user@master:/home/snapr_tools# bash/build_indices.sh
```

This script assumes that all files and directories are in place according to the previously run `prep_nodes.bash`. To build indices for a different species (human/mouse) or using different reference files, re-run `prep_nodes.sh` with these inputs.


## S3 data transfer and alignment

To run `snapr` on the target set of RNAseq files on S3, use the following script, which submits an individual `s3_snapr.sh` job for each file.

```
user@master:/home/snapr_tools# bash/submit_s3_snapr.sh -b s3_bucket
```

The `s3_bucket` input should be a valid S3 address (e.g., s3://seq-file-bucket), 

This step will take care of all data transfer from and to S3 as well as generation of `snapr` alignment results (to be stored on S3).

##### *Submit/data options*

The following input arguments can be used to provide more information about the data to be processed:

###### `-s subdir`

This argument can be used to specify the name of any top-level directories containing groups of samples. For example:

```
user@master:/home/snapr_tools# aws s3 ls s3://seq-file-bucket
                           PRE Case_Samples/
                           PRE Control_Samples/
```

In this case, an appropriate input for `subdir` would be `Case_Samples`. The final command would be structured as follows:

```
user@master:/snapr/snapr_tools# shell/submit_s3_snapr.sh -b s3://seq-file-bucket -s Control_Samples
```

###### `-L file_list`

This argument tells the submit script to refer to a local file containing a list of paths for data on the S3 bucket. For example:

```
user@master:/snapr/snapr_tools# head file_list
s3://seq-file-bucket/Case_Samples/sample1_reads_R1.fastq.gz
s3://seq-file-bucket/Case_Samples/sample1_reads_R1.fastq.gz
s3://seq-file-bucket/Case_Samples/sample2_reads_R2.fastq.gz
s3://seq-file-bucket/Case_Samples/sample2_reads_R2.fastq.gz
```
If a list of paths is provided, the submit script will not automatically search the S3 bucket for relevant filetypes and will only process the files listed. **Note:** if processing a list of files in a bucket subdirectory (see `-s subdir` above), listed paths should begin with the directory name, not with the bucket address.

###### `-f format (fastq/bam)`

This specifies the file format to search for and download from the S3 bucket. The default format is `fastq`.

###### `-m mode (single/paired)`

Mode specifies whether the data contains single or paired-end reads. If `mode` is `paired` and `format` is `fastq`, the script will automatically group, download, and process the appropriate pair of files for each sample.

###### `-l pair_file_label`

This label or tag denotes the set of characters or regular expression that distinguish between two paired-end read FASTQ files. For example, in the files shown above under the `-L file_list` description, `pair_file_label` would be `"_R[1-2]"`. A default label is included in the script, but I recommend providing this whenever processing paired-end FASTQ files, to ensure that files are accurately grouped.

## Output

Processing (or reprocessing) data with `snapr` will produce the following outputs for each sample:

+ Sorted BAM file [.snap.bam]
+ BAM index file [.snap.bam.bai]
+ Read counts per gene ID [.snap.gene_id.counts.txt]
+ Read counts per gene name [.snap.gene_name.counts.txt]
+ Read counts per transcript ID [.snap.transcript_id.counts.txt]
+ Read counts per transcript name [.snap.transcript_name.counts.txt]

The following outputs are also produced, but will currently be empty files with the current `snapr` settings:

+ [.snap.fusions.reads.fa]
+ [.snap.fusions.txt]
+ [.snap.interchromosomal.fusions.gtf]
+ [.snap.intrachromosomal.fusions.gtf]
+ [.snap.junction_id.counts.txt]
+ [.snap.junction_name.counts.txt]

Files will be saved at `s3://seq-file-bucket/subdir/snapr/`, if the `-s subdir` option is given; otherwise, files will be saved to `s3://seq-file-bucket/snapr/`.

You can also add the `-k` flag when calling `submit_s3_snapr.sh` to prevent output data from being copied back to S3 and keep saved on the cluster node (this is not recommended for large jobs, as disk space would likely fill up). Input and output files for each sample will be saved under `/data/` and `/results/`, respectively, on whichever node the sample was processed.


#### Example: processing paired FASTQ files

For this example, reference assembly files specific to chromosome 8 are provided in the `s3://snapr-ref-assemblies` bucket:

+ **Genome:** Homo_sampiens.GRCh38.dna.chromosome.8.fa
+ **Transcriptome:** chrom8.gtf

**1)**  Use the following command to set up all nodes on the cluster:

```
user@master:/home/snapr_tools# bash/prep_nodes.sh -g Homo_sampiens.GRCh38.dna.chromosome.8.fa -x chrom8.gtf
```

**2)** Once all `prep_nodes.sh` jobs have finished running (check progress with the `qstat` command), build genome and transcriptome indices on all nodes. 

```
user@master:/home/snapr_tools# bash/build_indices.sh
```

**3)** Process all paired FASTQ files in the bucket `s3://rna-editing-exdata` under the subdirectory `chr8`.

```
user@master:/home/snapr_tools# bash/submit_s3_snapr.sh -b s3://rna-editing-exdata -s subdir -f fastq -m paired -l "_[0-1]"
```

**Note:** You can use the `-d` flag to preview the first job that will be submitted to SGE, along with all inputs that would be provided to `s3_snapr.sh`. The end of the printed output should look like this:

```
### Job settings ###################################################

time bash/s3_snapr.sh -m paired  -l _[1-2] -d s3://rna-editing-exdata/chr8 -1 s3://rna-editing-exdata/chr8/SRR388226chrom8_1.fastq -2 s3://rna-editing-exdata/chr8/SRR388226chrom8_2.fastq -g /resources/genome/ -t /resources/transcriptome/ -x /resources/assemblies/ref-transcriptome.gtf
```

#### Example: reprocessing BAM files

This example also uses the chromosome 8 reference files described above. Steps **(1)** and **(2)** would therefore be identical.

**3)** Process all BAM files in the bucket `s3://rna-editing-exdata` under the subdirectory `chr8`.

```
user@master:/home/snapr_tools# bash/submit_s3_snapr.sh -b s3://rna-editing-exdata -s chr8 -f bam -m paired
```

With the `-d` flag included, the output should look like this:

```
### Job settings ###################################################

time bash/s3_snapr.sh -m paired -r -d s3://rna-editing-exdata/chr8 -1 s3://rna-editing-exdata/chr8/SRR388226.mq.bam -g /resources/genome/ -t /resources/transcriptome/ -x /resources/assemblies/ref-transcriptome.gtf
```
  
---

### Notes/warnings

+ `snapr` is run with the default options; changing these would currently require modifying the `s3_snapr.sh` code directly.
+ Lots of log files will be generated by SGE for the various steps above; I need to add some mechanisms to collate these logs and add some other relevant metadata about each specific pipeline run.