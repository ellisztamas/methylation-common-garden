#!/bin/bash
#
#SBATCH --job-name=mean_meth_old_script
#SBATCH --output=mean_meth_old_script.log
#
#SBATCH --mem-per-cpu=5GB
#SBATCH --qos=medium
#SBATCH --time=05:00:00
#SBATCH --ntasks=1
#
#SBATCH --array=0-192

# ENVIRONMENT #
module load anaconda3/2019.03
source $EBROOTANACONDA3/etc/profile.d/conda.sh

# Folder containing the HDF5 files
FILES=(/groups/nordborg/projects/cegs/rahul/014.fieldData/003.methylpy/002_3_fieldsamples_2019/hdf5/*hdf5)
# Folder to stores intermediate files for each HDF5 file
OUTPUT=005.results/004.compare_old_data/output/tmp
mkdir -p $OUTPUT
# Location of the script to run
LIB=005.results/004.compare_old_data/library/write_gw_methylation.py

srun python $LIB -f ${FILES[$SLURM_ARRAY_TASK_ID]} -o $OUTPUT