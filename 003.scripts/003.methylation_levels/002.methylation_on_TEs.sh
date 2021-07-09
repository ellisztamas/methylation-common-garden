#!/usr/bin/env bash

# Tom Ellis, July 2021, modifying code from Eriko Sasaki
#
# For a folder of allc files from the methylpy pipeline, this runs
# `002.library/perl/001.methylation_levels.pl` to count methylated
# and total reads on each annotated TE in a sample's genome, and 
# saves a `.tsv.gz` file for each sample.

#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10G
#SBATCH --output=./003.scripts/methylation_on_TEs.log
#SBATCH --qos=medium
#SBATCH --time=12:00:00
#SBATCH --array=0-479

module load perl/5.28.0-gcccore-7.3.0

# Where the data are
ALLC=004.output/001.methylseq/methylpy
# ALLC=/groups/nordborg/projects/cegs/rahul/014.fieldData/003.methylpy/002_3_fieldsamples_2019/allc
# Where to save the output
OUT=004.output/003.methylation_levels/reads_on_each_TE
INFO=001.data/002.reference_genome/Araport11_transposons_class.201606.txt

mkdir -p $OUT

ID=()
for file in $ALLC/*tsv.gz
do
    ID=(${ID[*]} `basename "$file"`)
done

Fname=${ID[$SLURM_ARRAY_TASK_ID]}
perl 002.library/perl/001.methylation_levels.pl ${ALLC} ${INFO} ${OUT} ${Fname}