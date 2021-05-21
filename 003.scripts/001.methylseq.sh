ml nextflow/21.02.0-edge

# Reference directories. Change these for your machine.
# Home folder for the project
PROJ=~/common_gardens
# Working directory to perform computations on the VBC cluster.
DIR=/scratch-cbe/users/thomas.ellis

# Where the data are
# Reference genome
ref_genome=$PROJ/001.data/001.raw/TAIR10_wholeGenome.fasta
# Location of the raw zip file on the VBC cluster
RAW=$PROJ/001.data/001.raw/001.raw_reads

# Where to save the output
DATA=$DIR/data # where to unzip raw reads
WORK=$DIR/000.work/001.methylseq # Nextflow working directory
MSEQ=$DIR/001.methylseq # where to output results of the pipeline
OUT=$PROJ/001.data/002.processed # where to copy the data when finished

mkdir -p $DATA
mkdir -p $MSEQ
mkdir -p $WORK
mkdir -p $OUT

# Unzip raw data
# Plate 144
unzip $RAW/CDN24ANXX_2_M8584.zip -d $DATA
unzip $RAW/CDN24ANXX_3_M8585.zip -d $DATA
unzip $RAW/CDN24ANXX_4_M8587.zip -d $DATA
unzip $RAW/CDN24ANXX_5_M8588.zip -d $DATA
# Plate 145
unzip $RAW/CDN2BANXX_1_M8246.zip -d $DATA
unzip $RAW/CDN2BANXX_4.zip -d $DATA
unzip $RAW/CDN2BANXX_5.zip -d $DATA
unzip $RAW/CDN2BANXX_6.zip -d $DATA
# Plate 167
zipfile=$RAW/elxRjzjh9h-HKKWJDRXX_20200415B_demux_2_R9456.zip
unzip $zipfile -d $DATA
# Plate 168
# zipfile=$RAW/anQaf5Iadx-HMYF5DRXX_20200928B_demux_1_R10191.zip
# unzip $zipfile -d $DATA
# Plate 169
zipfile=$RAW/Tjpak3IDx6-HMYF5DRXX_20200928B_demux_2_R10191.zip
unzip $zipfile -d $DATA

# Run nextflow
nextflow run ~/methylseq/main.nf \
-profile cbe,singularity \
--input "$DATA/[CH]*/*.bam" \
--fasta $ref_genome \
--outdir $MSEQ \
--umeth "ChrC:" \
--clip_r2 15 \
--aligner bismark \
--relax_mismatches \
--num_mismatches 0.5 \
--file_ext bam \
-w $WORK \
-resume
# Copy these results to the permanent projects folder
stage $MSEQ $OUT