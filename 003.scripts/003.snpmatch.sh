# Tom Ellis, May 2021
# Commands to run the nextflow SNPmatch pipeline on each sample.
# See https://github.com/rbpisupati/nf-snpmatch

ml nextflow/21.02.0-edge

# Reference directories. Change these for your machine.
# Home folder for the project
PROJ=~/common_gardens
# Working directory to perform computations on the VBC cluster.
DIR=/scratch-cbe/users/thomas.ellis

# Where the data are
# Reference genome
ref_genome=$PROJ/001.data/001.raw/TAIR10_wholeGenome.fasta
# Output of the methylseq pipeline
MSEQ=$DIR/001.methylseq
# Matrix of known SNP positions. This means SNPs do not need to be called on the the bisulphite data
KNOWN_SITES=$PROJ/001.data/001.raw/known_sites.tsv.gz
# Folder with the database files for SNPmatch
DB=$PROJ/001.data/001.raw/002.snpmatch

# Where to save the output
CALLS=$DIR/genotype_calls
MATCH=$DIR/001.snpmatch
OUT=$PROJ/004.output

mkdir -p $CALLS
mkdir -p $DIR/work/genotype_calls
mkdir -p $DIR/work/snpmatch
mkdir -p $MATCH
mkdir -p $OUT

# Run the genotype calling pipeline
nextflow run ~/nf-haplocaller/snps_bsseq.nf \
--input "$MSEQ/bismark_deduplicated/*.bam" \
--fasta $ref_genome \
--outdir $CALLS \
-w $DIR/work/genotype_calls \
--known-sites $KNOWN_SITES \
-profile conda

# Run the pipeline
nextflow run ~/nf-snpmatch/main.nf \
--func "inbred" \
--input "${CALLS}/variants_bcftools/*.vcf.gz" \
--outdir $MATCH \
--db $DB/1135g_SNP_BIALLELIC.hetfiltered.snpmat.6oct2015.hdf5 \
--db_acc $DB/1135g_SNP_BIALLELIC.hetfiltered.snpmat.6oct2015.acc.hdf5 \
-w $DIR/work/snpmatch

stage $MATCH $OUT