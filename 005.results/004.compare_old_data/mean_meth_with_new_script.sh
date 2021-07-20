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
# by Rahul in 2019.

# ENVIRONMENT #
module load anaconda3/2019.03
source $EBROOTANACONDA3/etc/profile.d/conda.sh

# Where the data are
ALLC='/groups/nordborg/projects/cegs/rahul/014.fieldData/003.methylpy/002_3_fieldsamples_2019/allc'
# Where to save the output
OUT=005.results/004.compare_old_data/output
mkdir -p $OUT

# Create an empty file with a header
echo "file,chr_type,CG,CHG,CHH,coverage" > $OUT

FILES=($ALLC/'allc_*.tsv.gz')
for f in $FILES; do
  python3 002.library/python/weighted_mean_mC_from_allc.py \
  --input $f \
  --output $OUT/mean_meth_from_new_script.csv
done