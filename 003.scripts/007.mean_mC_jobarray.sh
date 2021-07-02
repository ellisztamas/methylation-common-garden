#!/usr/bin/env bash

# SLURM
#SBATCH --job-name=mean_mC_jobarray
#SBATCH --output=mean_mC_jobarray.log
#SBATCH --mem-per-cpu=5GB
#SBATCH --qos=medium
#SBATCH --time=12:00:00
#SBATCH --ntasks=1

# Tom Ellis, June 2021
# SLURM script to calculate weighted-mean methylation levels in CG, 
# CHG and CHH sequence contexts for a folder of allc files generated
# by the methylpy pipeline.
#
# This loops over each allc file, calculates numbers, and sends them
# to an output summary file. This would be faster as a job array, but 
# I wanted to be sure that the output file was created and updated
# within a single script.

# ENVIRONMENT #
module load anaconda3/2019.03
source $EBROOTANACONDA3/etc/profile.d/conda.sh

# Where the data are
ALLC='001.data/002.processed/001.methylseq/methylpy/'
# Where to save the output
OUT='001.data/002.processed/mean_mC_genome_wide.csv'

# Create an empty file with a header
echo "file,CG,CHG,CHH" > $OUT

FILES=($ALLC/'allc_*.tsv.gz')
for f in $FILES; do
  python3 002.library/python/weighted_mean_mC_from_allc.py \
  --input $f \
  --output $OUT
done