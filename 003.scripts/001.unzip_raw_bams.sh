#!/usr/bin/env bash
# 
# Tom Ellis
# Script to unzip each raw data file to the `scratch-cbe` drive
# on the VBC cluster.
# Reads for plates run on a NovaSeq machine are split across two BAM
# files, so for those plates reads are combined using samtools.

# SLURM
#SBATCH --mem=5GB
#SBATCH --output=./003.scripts/unzip_raw_bams.log
#SBATCH --qos=medium
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=8



# Environment
ml samtools/1.9-foss-2018b

# Reference directories. Change these for your machine.
# Home folder for the project
PROJ=~/common_gardens
# Working directory to perform computations on the VBC cluster.
DIR=/scratch-cbe/users/thomas.ellis

# Where the data are
# Location of the raw zip file on the VBC cluster
RAW=$PROJ/001.data/001.raw/001.raw_reads

# Where to save the output
DATA=$PROJ/001.data/001.raw/002.unzipped_raw_bams # where to unzip raw reads

mkdir -p $DATA

# Unzip raw data
# Plate 144
unzip -n $RAW/CDN24ANXX_2_M8584.zip -d $DATA
unzip -n $RAW/CDN24ANXX_3_M8585.zip -d $DATA
unzip -n $RAW/CDN24ANXX_4_M8587.zip -d $DATA
unzip -n $RAW/CDN24ANXX_5_M8588.zip -d $DATA
mkdir -p $DATA/144
mv $DATA/CDN24ANXX*/* $DATA/144
# Plate 145
unzip -n $RAW/CDN2BANXX_1_M8246.zip -d $DATA
unzip -n $RAW/CDN2BANXX_4.zip -d $DATA
unzip -n $RAW/CDN2BANXX_5.zip -d $DATA
unzip -n $RAW/CDN2BANXX_6.zip -d $DATA
mkdir -p $DATA/145
mv $DATA/CDN2BANXX*/* $DATA/145
# Plate 167
# This is multiplexed with data for Alexandra Kornienko
zipfile=$RAW/elxRjzjh9h-HKKWJDRXX_20200415B_demux_2_R9456.zip
unzip -n $zipfile -d $DATA
zipfile=$RAW/CvYzSBEAdM-HKKWJDRXX_20200415B_demux_1_R9456.zip
unzip -n $zipfile -d $DATA
# Plates 168 and 169 are multiplexed over two zip files.
zipfile=$RAW/anQaf5Iadx-HMYF5DRXX_20200928B_demux_1_R10191.zip
unzip -n $zipfile -d $DATA
zipfile=$RAW/Tjpak3IDx6-HMYF5DRXX_20200928B_demux_2_R10191.zip
unzip -n $zipfile -d $DATA

# Plates 167 to 169 were run on a NovaSeq machine
# Reads for each sample are split into files in separate zip files, because of some NovaSeq voodoo.
# Plate 167 has code 115306
mkdir -p $DATA/167
d1=($DATA/HKKWJDRXX_20200415B_demux_1_R9456/*115306*bam)
d2=($DATA/HKKWJDRXX_20200415B_demux_2_R9456/*115306*bam)

for index in ${!d1[*]}; do 
  samtools merge --threads 4 $DATA/167/`basename ${d1[$index]}` ${d1[$index]} ${d2[$index]}
done
cp $DATA/HKKWJDRXX*/*barcodes.json $DATA/167

# Plate 168 has the code 128708
mkdir -p $DATA/168
d1=($DATA/HMYF5DRXX_20200928B_demux_1_R10191/*128708*bam)
d2=($DATA/HMYF5DRXX_20200928B_demux_2_R10191/*128708*bam)
for index in ${!d1[*]}; do 
  samtools merge --threads 4 $DATA/168/`basename ${d1[$index]}` ${d1[$index]} ${d2[$index]}
done
cp $DATA/HMYF5DRXX_20200928B_demux_*/*barcodes.json $DATA/168

# Plate 169 has the code 128709
mkdir -p $DATA/169
d1=($DATA/HMYF5DRXX_20200928B_demux_1_R10191/*128709*bam)
d2=($DATA/HMYF5DRXX_20200928B_demux_2_R10191/*128709*bam)
for index in ${!d1[*]}; do 
  samtools merge --threads 4 $DATA/169/`basename ${d1[$index]}` ${d1[$index]} ${d2[$index]}
done
cp $DATA/HMYF5DRXX_20200928B_demux_*/*barcodes.json $DATA/169