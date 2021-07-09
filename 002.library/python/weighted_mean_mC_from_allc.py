"""
Tom Ellis, June 2021

Get the weighted mean methylation (i.e. the sum of methylated reads divided by the 
sum of all reads) over cytosines within an allc file from the methylpy pipeline
(https://github.com/yupenghe/methylpy).

Since allc files are very large, they are read into memory chunks by pandas.read_csv,
and number of reads summed over chunks.

Parameters
----------
input: str
    Path to allc file from the methylpy pipeline
output: str
    Path to the file to which results should be appended.
chunksize: int
    `chunksize` argument passed to pandas.read_csv
chunks_to_test: None or int
    Optional parameter to allow testing on a small number of chunks. If an integer
    less than the number of chunks is given, the function will  be run on these
    chunks only.

Returns
-------
`output` is appended with the name of the input file, followed by weighted-
mean methylation levels for the CG, CHG and CHH sequence contexts.
"""

import pandas as pd
import numpy as np
import argparse
import os

parser = argparse.ArgumentParser(description = 'Parse parameters for multilocus GWAS')
parser.add_argument('-i', '--input', help = 'Path to allc file from the methylpy pipeline', required = True)
parser.add_argument('-o', '--output', help = 'Path to the file to which results should be appended.', required = True)
args = parser.parse_args()

allc = pd.read_csv(
    args.input,
    compression='gzip',
    sep="\t",
    names = ["chr", "pos", "strand", "seq", "mC_reads", "all_reads", "signif"]
    )

# Empty dataframe to store read counts for methylated un unmethylated cytosines.
sum_mC = pd.DataFrame({
    'mC_reads' : [0,0,0,0],
    'all_reads' : [0,0,0,0]
},index=['CG', "CHG", "CHH", 'coverage']
)

# Weighted mean methylation over cytosines on autosomes.
autosomes = allc.loc[allc['chr'].isin(['Chr1', 'Chr2', 'Chr3', 'Chr4', 'Chr5'])]
sum_mC = pd.DataFrame({
        'CG' : autosomes[['mC_reads', "all_reads"]].\
            loc[autosomes['seq'].str.match('CG.')].\
                sum(0),
        'CHG' : autosomes[['mC_reads', "all_reads"]].\
            loc[autosomes['seq'].str.match('C[ACT]G')].\
                sum(0),
        'CHH' : autosomes[['mC_reads', "all_reads"]].\
            loc[autosomes['seq'].str.match('C[ACT][ACT]')].\
                sum(0),
        'coverage' : np.array([ autosomes['all_reads'].sum(), allc.shape[0] ])
    }).T

weighted_means = (sum_mC['mC_reads'] / sum_mC['all_reads']).round(5).astype(str).to_list()
# Write input file name plus weighted means for autosomes to disk.
out= open(args.output, 'a') 
out.write(
    os.path.basename(args.input) + 'autosomes' + ',' + ','.join(weighted_means) + '\n'
)
out.close()

# Weighted mean methylation over cytosines on mitochondria and chloroplasts.
organelles = allc.loc[allc['chr'].isin(['ChrC', 'ChrM'])]
sum_mC = pd.DataFrame({
        'CG' : organelles[['mC_reads', "all_reads"]].\
            loc[organelles['seq'].str.match('CG.')].\
                sum(0),
        'CHG' : organelles[['mC_reads', "all_reads"]].\
            loc[organelles['seq'].str.match('C[ACT]G')].\
                sum(0),
        'CHH' : organelles[['mC_reads', "all_reads"]].\
            loc[organelles['seq'].str.match('C[ACT][ACT]')].\
                sum(0),
        'coverage' : np.array([ organelles['all_reads'].sum(), allc.shape[0] ])
    }).T
weighted_means = (sum_mC['mC_reads'] / sum_mC['all_reads']).round(5).astype(str).to_list()
# Write input file name plus weighted means for organelles to disk.
out= open(args.output, 'a') 
out.write(
    os.path.basename(args.input) + ',organelles,' + ','.join(weighted_means) + '\n'
)
out.close()