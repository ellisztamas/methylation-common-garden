# Tom Ellis, May 2021
# Commands to call genotypes for plate 144.
# This assumes you have already run the methylseq pipeline (see 
# `003.scripts/001.methylseq`) and you have the nf-haplocaller nextflow
# pipeline in your root folder (wherever `~` takes you).

ml nextflow/21.02.0-edge

# ID for the sequencing plate being processed
PLATE=144

# Reference directories. Change these for your machine.
# Home folder for the project
PROJ=~/common_gardens
# Working directory to perform computations on the VBC cluster.
DIR=/scratch-cbe/users/thomas.ellis

# Where the data are
# Reference genome
ref_genome=$PROJ/001.data/001.raw/TAIR10_wholeGenome.fasta
# Output of the methylseq pipeline
MSEQ=$DIR/001.methylseq/$PLATE
# Matrix of known SNP positions. This means SNPs do not need to be called on the the bisulphite data
KNOWN_SITES=$PROJ/001.data/001.raw/known_sites.tsv.gz

# Where to save the output
CALLS=$DIR/002.genotype_calls/$PLATE
WORK=/$DIR/000.work/002.genotype_calls/$PLATE
OUT=$PROJ/001.data/002.processed/002.genotype_calls
mkdir -p $CALLS
mkdir -p $WORK
mkdir -p $OUT

# Run the genotype calling pipeline
nextflow run ~/nf-haplocaller/snps_bsseq.nf \
--input "$MSEQ/bwa-mem_markDuplicates/*.bam" \
--fasta $ref_genome \
--outdir $CALLS \
-w $WORK \
--known-sites $KNOWN_SITES \
-profile conda
# Copy these results to the permanent projects folder
stage $CALLS $OUT