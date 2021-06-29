# Tom Ellis, May 2021
# Commands to run the nextflow haplocaller pipeline on each sample to
# call genotypes from bisulphite data. SNP postions are not called 
# afresh from BS data, but reads are compared to a known SNP matrix.
#
# In many cases, one allele was not present in the reference matrix,
# which led to weird results later on. To circumvent this, samples 
# are lumped into a single VCF file and observed nucleotides are used.
# This prevents SNPmatch thinking everthing in Columbia.
#
# See https://github.com/Gregor-Mendel-Institute/nf-haplocaller for
# pipeline information.
#
# It is assumed that you have previously run the methylseq pipeline
# on unaligned BAM files; see `003.scripts/002.methylseq.sh`

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
DB=$PROJ/001.data/001.raw/003.snpmatch

# Where to save the output
CALLS=$DIR/genotype_calls

mkdir -p $CALLS
mkdir -p $DIR/work/genotype_calls

# Run the genotype calling pipeline
# Argument `cohort` tells the pipeline to lump samples together and use observed SNPs
nextflow run ~/nf-haplocaller/snps_bsseq.nf \
--input "$MSEQ/bismark_deduplicated/*.bam" \
--fasta $ref_genome \
--outdir $CALLS \
--cohort calls \
-w $DIR/work/genotype_calls \
--known-sites $KNOWN_SITES \
-profile conda