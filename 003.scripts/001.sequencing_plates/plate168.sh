# Tom Ellis, May 2021
# Commands to process bisulphite data for plate 168
# (One plant per accession per site from two sites)

ml nextflow/21.02.0-edge

ref_genome=/groups/nordborg/projects/the1001genomes/scratch/1001.TAIR10.genome/TAIR10_wholeGenome.fasta

DIR=/scratch-cbe/users/thomas.ellis/plate_168
WORK=$DIR/000.work
OUT=/groups/nordborg/projects/epiclines/001.common_gardens/001.data/002.processed/plate_168

mkdir -p $DIR
mkdir -p $WORK
mkdir -p $OUT

###### METHYLSEQ PIPELINE #######
MSEQ=$DIR/001.methylseq
mkdir -p $MSEQ
mkdir -p $WORK/001.methylseq
# Unzip raw data
zipfile=/groups/nordborg/projects/nordborg_rawdata/Athaliana/bisulfite_seq/field_data_from_2012/anQaf5Iadx-HMYF5DRXX_20200928B_demux_1_R10191.zip
unzip $zipfile -d $DIR
# Run the pipeline
nextflow run ~/methylseq/main.nf \
-profile cbe,singularity \
--reads "${DIR}/HMYF5DRXX_20200928B_demux_1_R10191/*.bam" \
--fasta $ref_genome \
--outdir $MSEQ \
--aligner bwameth \
-w $WORK/001.methylseq \
--email thomas.ellis@gmi.oeaw.ac.at \
--email_on_fail thomas.ellis@gmi.oeaw.ac.at
# Stage it to projects
stage $MSEQ $OUT

####### Genotype calling #######
CALLS=$DIR/002.snps_bsseq
mkdir -p $CALLS
mkdir -p $WORK/002.snps_bsseq
# Matrix of known SNP positions. This means SNPs do not need to be called on the the bisulphite data
KNOWN_SITES=/groups/nordborg/projects/the1001genomes/scratch/rahul/101.VCF_1001G_1135/1135g_SNP_BIALLELIC.tsv.gz
# Run the genotype calling pipeline
nextflow run ~/nf-haplocaller/snps_bsseq.nf \
--input "${MSEQ}/bwa-mem_markDuplicates/*.bam" \
--fasta $ref_genome \
--outdir $CALLS \
-w $WORK/002.snps_bsseq \
--known-sites $KNOWN_SITES \
-profile conda