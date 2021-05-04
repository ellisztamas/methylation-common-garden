# Tom Ellis, May 2021
# Commands to process bisulphite data for plate 144
# (Plants from 12 accessions with multiple replicates per plant)

ml nextflow/21.02.0-edge

ref_genome=/groups/nordborg/projects/the1001genomes/scratch/1001.TAIR10.genome/TAIR10_wholeGenome.fasta

DIR=/scratch-cbe/users/thomas.ellis/plate_144
WORK=$DIR/000.work
OUT=/groups/nordborg/projects/epiclines/001.common_gardens/001.data/002.processed/plate_144

mkdir -p $DIR
mkdir -p $WORK
mkdir -p $OUT

###### METHYLSEQ PIPELINE #######
MSEQ=$DIR/001.methylseq
mkdir -p $MSEQ
mkdir -p $WORK/001.methylseq
# These seems to be divided into four zip files
RAW=/groups/nordborg/projects/nordborg_rawdata/Athaliana/bisulfite_seq/field_data_from_2012/
unzip $RAW/CDN24ANXX_2_M8584.zip -d $DIR
unzip $RAW/CDN24ANXX_3_M8585.zip -d $DIR
unzip $RAW/CDN24ANXX_4_M8587.zip -d $DIR
unzip $RAW/CDN24ANXX_5_M8588.zip -d $DIR
# Run the nextflow run
nextflow run ~/methylseq/main.nf \
-profile cbe,singularity \
--reads "${DIR}/CDN24ANXX_*M85*/*.bam" \
--fasta $ref_genome \
--outdir $MSEQ \
--aligner bwameth \
-w $WORK/001.methylseq \
--email thomas.ellis@gmi.oeaw.ac.at \
--email_on_fail thomas.ellis@gmi.oeaw.ac.at \
--umeth chrc: \
-resume
# Stage it to projects
stage $MSEQ $OUT

####### Genotype calling #######
CALLS=$DIR/002.snps_bsseq
mkdir -p $CALLS
mkdir -p $WORK/002.snps_bsseq

# nextflow run ~/nf-haplocaller/snps_bsseq.nf \
# --input "${MSEQ}/bwa-mem_markDuplicates/*.bam" \
# --fasta $ref_genome \
# --outdir $CALLS \
# -w $WORK/002.snps_bsseq \
# --known-sites /groups/nordborg/projects/the1001genomes/scratch/rahul/101.VCF_1001G_1135/1135g_SNP_BIALLELIC.tsv.gz \
# -profile conda \
# -resume

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

####### SNP Match #######
MATCH=$DIR/003.snp_match
mkdir -p $MATCH
mkdir -p $WORK/003.snp_match

nextflow run main.nf --func "inbred" --input "*.vcf" --outdir "snpmatch" --db "hdf5" --db_acc "hdf5_acc"