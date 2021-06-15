ml nextflow/21.02.0-edge

# Reference directories. Change these for your machine.
# Home folder for the project
PROJ=~/common_gardens
# Working directory to perform computations on the VBC cluster.
DIR=/scratch-cbe/users/thomas.ellis

# Where the data are
# Reference genome
ref_genome=$PROJ/001.data/001.raw/TAIR10_wholeGenome.fasta
DATA=$DIR/data # where unzipped reads are saved

# Where to save the output
WORK=$DIR/000.work/001.methylseq # Nextflow working directory
MSEQ=$DIR/001.methylseq # where to output results of the pipeline
OUT=$PROJ/001.data/002.processed # where to copy the data when finished

mkdir -p $MSEQ
mkdir -p $WORK
mkdir -p $OUT

# Run nextflow
nextflow run ~/methylseq/main.nf \
-profile cbe,singularity \
--input "$DATA/plate*/*.bam" \
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