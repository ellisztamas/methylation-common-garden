#!/usr/bin/env bash

# Tom Ellis, June 2021
# SLURM script to separate the single very large VCF file created by
# `003.scripts/003.genotype_calls.sh` into individual VCF files.

# SLURM
#SBATCH --mem=5GB
#SBATCH --output=./003.scripts/split_vcf.log
#SBATCH --qos=medium
#SBATCH --time=48:00:00

ml bcftools/1.9-foss-2018b

# Reference directories. Change these for your machine.
# Home folder for the project
PROJ=~/common_gardens
# Working directory to perform computations on the VBC cluster.
DIR=/scratch-cbe/users/thomas.ellis
# VCF file for all samples at once
FILE=$DIR/genotype_calls/calls.qual_filtered.vcf.gz

# Loop over vcfs and save split into its own VCF
for file in $FILE; do
  for sample in `bcftools query -l $file`; do
    bcftools view -c1 -Oz -s $sample -o ${file/.vcf*/.$sample.vcf.gz} $file
  done
done