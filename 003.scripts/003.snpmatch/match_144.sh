# Tom Ellis, May 2021
# Commands to run the nextflow SNPmatch pipeline on each sample.
# See https://github.com/rbpisupati/nf-snpmatch

# ID for the sequencing plate being processed
PLATE=144

# Reference directories. Change these for your machine.
# Home folder for the project
PROJ=~/common_gardens
# Working directory to perform computations on the VBC cluster.
DIR=/scratch-cbe/users/thomas.ellis

# Where the data are
# Genotype calls for each sample
CALLS=$DIR/002.genotype_calls/$PLATE
# Folder with the database files for SNPmatch
DB=$PROJ/001.data/001.raw/002.snpmatch

# Set up paths to working directories
MATCH=$DIR/003.snpmatch/$PLATE
OUT=$PROJ/001.data/002.processed/003.snpmatch
mkdir -p $MATCH
mkdir -p $OUT

# Run the pipeline
nextflow run ~/nf-snpmatch/main.nf \
--func "inbred" \
--input "${CALLS}/variants_bcftools/*.vcf.gz" \
--outdir $MATCH \
--db $DB/1135g_SNP_BIALLELIC.hetfiltered.snpmat.6oct2015.hdf5 \
--db_acc $DB/1135g_SNP_BIALLELIC.hetfiltered.snpmat.6oct2015.acc.hdf5

stage $MATCH $OUT