#!/usr/bin/env bash

# SLURM
#SBATCH --mem=10GB
#SBATCH --output=/scratch-cbe/users/thomas.ellis/allc_144.log
#SBATCH --qos=medium
#SBATCH --time=24:00:00
#SBATCH --array=0-95

# ENVIRONMENT #
ml build-env/2020
ml methylpy/1.2.9-foss-2018b-python-2.7.15

# ID for the sequencing plate being processed
PLATE=144

# Reference directories. Change these for your machine.
# Home folder for the project
PROJ=~/common_gardens
# Working directory to perform computations on the VBC cluster.
DIR=/scratch-cbe/users/thomas.ellis

# Where the data are
# Reference genome
ref_genome=$PROJ/001.data/001.raw/TAIR10_wholeGenome.fasta
# Aligned bam files from the methylseq pipeline
MSEQ=$DIR/001.methylseq/$PLATE
FILES=($MSEQ/bwa-mem_markDuplicates/*.bam)
SAMPLE=$(basename ${FILES[$SLURM_ARRAY_TASK_ID]} .bam)

# Where to save the output
ALLC=$DIR/004.allc/$PLATE # where to store allc files
OUT=$PROJ/001.data/002.processed/004.allc/ # where to copy the data when finished

mkdir -p $ALLC
mkdir -p $OUT

# Run the script
methylpy call-methylation-state \
	--input-file ${FILES[$SLURM_ARRAY_TASK_ID]} \
	--paired-end True \
	--path-to-output $ALLC \
	--sample $SAMPLE \
	--ref-fasta $ref_genome

stage $ALLC $OUT