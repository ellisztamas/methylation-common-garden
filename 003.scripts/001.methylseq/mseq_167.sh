# Tom Ellis, May 2021
# Commands to process bisulphite data for plate 167
# (One plant per accession per site from two sites)
# This assumes you have the nf-methylseq pipeline in your root folder
# (wherever `~` takes you).

ml nextflow/21.02.0-edge

# ID for the sequencing plate being processed
PLATE=167

# Reference directories. Change these for your machine.
# Home folder for the project
PROJ=~/common_gardens
# Working directory to perform computations on the VBC cluster.
DIR=/scratch-cbe/users/thomas.ellis

# Where the data are
# Reference genome
ref_genome=$PROJ/001.data/001.raw/TAIR10_wholeGenome.fasta
# Location of the raw zip file on the VBC cluster
RAW=$PROJ/001.data/001.raw/001.raw_reads

# Where to save the output
DATA=$DIR/data/$PLATE # where to unzip raw reads
MSEQ=$DIR/001.methylseq/$PLATE # where to output results of the pipeline
WORK=$DIR/000.work/001.methylseq/$PLATE # Nextflow working directory
OUT=$PROJ/001.data/002.processed/001.methylseq # where to copy the data when finished

mkdir -p $DATA
mkdir -p $MSEQ
mkdir -p $WORK
mkdir -p $OUT

# Unzip raw data
zipfile=$RAW/elxRjzjh9h-HKKWJDRXX_20200415B_demux_2_R9456.zip
unzip $zipfile -d $DATA
# Run the pipeline
nextflow run ~/methylseq/main.nf \
-profile cbe,singularity \
--reads "${DATA}/HKKWJDRXX_20200415B_demux_2_R9456/*.bam" \
--fasta $ref_genome \
--outdir $MSEQ \
--aligner bwameth \
-w $WORK \
--email thomas.ellis@gmi.oeaw.ac.at \
--email_on_fail thomas.ellis@gmi.oeaw.ac.at
# Stage it to projects
stage $MSEQ $OUT