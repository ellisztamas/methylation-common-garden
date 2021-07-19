# Tom Ellis, May 2021
# Commands to run the nextflow SNPmatch pipeline on each VCF file.
# See https://github.com/rbpisupati/nf-snpmatch for pipeline info.

ml nextflow/21.02.0-edge

# Reference directories. Change these for your machine.
# Home folder for the project
PROJ=~/common_gardens
# Working directory to perform computations on the VBC cluster.
DIR=/scratch-cbe/users/thomas.ellis

# Where the data are
# Reference genome
ref_genome=$PROJ/001.data/002.reference_genome/TAIR10_wholeGenome.fasta
# Output of the methylseq pipeline
CALLS=$DIR/genotype_calls
# Folder with the database files for SNPmatch
DB=$PROJ/001.data/003.snpmatch_files

# Where to save the output
MATCH=$DIR/001.snpmatch
OUT=$PROJ/004.output/002.link_samples/

mkdir -p $DIR/work/snpmatch
mkdir -p $MATCH
mkdir -p $OUT

# Run the pipeline
nextflow run ~/nf-snpmatch/main.nf \
--func "inbred" \
--input "${CALLS}/calls.qual_filtered.[HC]*.vcf.gz" \
--outdir $MATCH \
--db $DB/1135g_SNP_BIALLELIC.hetfiltered.snpmat.6oct2015.hdf5 \
--db_acc $DB/1135g_SNP_BIALLELIC.hetfiltered.snpmat.6oct2015.acc.hdf5 \
-w $DIR/work/snpmatch

stage $MATCH $OUT