# Tom Ellis May-June 2021
# Commands to run the methylseq pipeline on unaligned BAM files on the 
# VBC cluster. This assumes you have previously unzipped those files using
# `003.scripts/001.methylseq/001.unzip_raw_bams.sh`.
# See https://github.com/yupenghe/methylpy for pipeline details.

ml nextflow/21.02.0-edge

# Reference directories. Change these for your machine.
# Home folder for the project
PROJ=~/common_gardens
# Working directory to perform computations on the VBC cluster.
DIR=/scratch-cbe/users/thomas.ellis

# Where the data are
# Reference genome
ref_genome=$PROJ/001.data/002.reference_genome/TAIR10_wholeGenome.fasta
DATA=$PROJ/001.data/001.sequencing/002.unzipped_raw_bams/ # where unzipped reads are saved

# Where to save the output
WORK=$DIR/000.work/001.methylseq # Nextflow working directory
MSEQ=$DIR/001.methylseq # where to output results of the pipeline
OUT=$PROJ/004.output # where to copy the data when finished

mkdir -p $MSEQ
mkdir -p $WORK
mkdir -p $OUT

# Run nextflow
nextflow run ~/methylseq/main.nf \
-profile cbe,singularity \
--input "$DATA/*/*.bam" \
--fasta $ref_genome \
--outdir $MSEQ \
--umeth "ChrC:" \
--clip_r1 15 \
--clip_r2 15 \
--aligner bismark \
--relax_mismatches \
--num_mismatches 0.5 \
--file_ext bam \
-w $WORK    
# -resume
# Copy these results to the permanent projects folder
stage $MSEQ $OUT
