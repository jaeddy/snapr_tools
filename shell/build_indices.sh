
#copy fasta and gtf files and create indices for snapr

cd /mnt

#this should copy at least two files: the fasta and gtf file to the /mnt drive
cp /snapr-cory/assembly/human/Homo_sapiens.GRCh38*  

#if these aren't already made on the /mnt drive, make them
mkdir genome20
mkdir transcriptome20

snapr index Homo_sapiens.GRCh38.dna.SORTED.fa /mnt/genome20 -bSpace
snapr transcriptome Homo_sapiens.GRCh38.76.gtf Homo_sapiens.GRCh38.dna.SORTED.fa /mnt/transcriptome20 -bSpace