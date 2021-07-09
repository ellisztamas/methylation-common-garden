#!/usr/bin/env bash

# SLURM
#SBATCH --job-name=mean_mC_jobarray
#SBATCH --output=mean_mC_genome_wide.log
#SBATCH --mem-per-cpu=16GB
#SBATCH --qos=medium
#SBATCH --time=12:00:00
#SBATCH --ntasks=1

# Tom Ellis, June 2021
# SLURM script to calculate weighted-mean methylation levels in CG, 
# CHG and CHH sequence contexts for a folder of allc files generated
# by the methylpy pipeline.
# 
# Methylation is calculated for both autosomes and organelles
# (mitochondria and chloroplasts).
#
# This loops over each allc file, calculates numbers, and sends them
# to an output summary file. This would be faster as a job array, but 
# I wanted to be sure that the output file was created and updated
# within a single script.

# ENVIRONMENT #
module load anaconda3/2019.03
source $EBROOTANACONDA3/etc/profile.d/conda.sh

# Where the data are
ALLC='004.output/001.methylseq/methylpy/'
# Where to save the output
OUT='004.output/003.methylation_levels/mean_mC_genome_wide.csv'

# Create an empty file with a header
echo "file,chr_type,CG,CHG,CHH,coverage" > $OUT

FILES=($ALLC/'allc_*.tsv.gz')
for f in $FILES; do
  python3 002.library/python/weighted_mean_mC_from_allc.py \
  --input $f \
  --output $OUT
done

# python3 002.library/python/weighted_mean_mC_from_allc.py \
# --input $ALLC/allc_HMYF5DRXX_1#128709_TAGGCATGCGCTAGAG.tsv.gz \
# --output $OUT