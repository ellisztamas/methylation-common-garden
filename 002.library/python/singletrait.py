#!/bin/python

'''
Script to run marginal GWAS

Pieter Clauw
'''

from limix.qtl import scan
import pandas as pd
import numpy as np
import h5py
from bisect import bisect
from limix import plot
import random
from sklearn.decomposition import PCA
import argparse
import os
from statsmodels.stats import multitest
import math

# Parameters
parser = argparse.ArgumentParser(description = 'Parse parameters for multilocus GWAS')
parser.add_argument('-p', '--phenotype',help = 'Path to phenotype file. CSV file with accession ID in forst column, phenptype values in second column. Filename is used as phenotype name.', required = True)
parser.add_argument('-g', '--genotype', help = 'Path to genotype directory.This directory should contain boht the SNP and kinship matrix. Versions are the same as used for PyGWAS.', required = True)
parser.add_argument('-m', '--maf', help = 'Specify the minor allele frequecny cut-off. Default is set to 0.05', default = 0.05)
parser.add_argument('-o', '--outDir', help = 'Specify the output directory. All results will be saved in this directory.', required = True)
parser.add_argument('-c', '--covariates', help = 'Path to matrix of covariates', required=False, type=str)
parser.add_argument('-l', '--link', help = 'Link function for the GLM', required=False, default="normal", type=str)
args = parser.parse_args()

# Phenotype (Y)
pheno = pd.read_csv(args.phenotype, index_col = 0)
trait = os.path.basename(args.phenotype)[:-4] 
# remove NA values
pheno = pheno[np.isfinite(pheno[pheno.keys()[0]])]
# enocde pheno.index to UTF8, for complemetarity with SNP matrix accessions
pheno.index = pheno.index.map(lambda x: str(x).encode('UTF8'))
acnNrInitial = len(pheno.index)

# Genotype (G)
genoFile = f'{args.genotype}/all_chromosomes_binary.hdf5'
geno_hdf = h5py.File(genoFile, 'r')

acn_indices = [np.where(geno_hdf['accessions'][:] == acn)[0][0] for acn in pheno.index]
acn_indices.sort()
acn_order = geno_hdf['accessions'][acn_indices]
G = geno_hdf['snps'][:, acn_indices]
# subset pheno in case of non-genotyped accessions
if len(acn_indices) != len(pheno.index):
    acns = list(set(pheno.index) & set(geno_hdf['accessions'][:]))
    pheno = pheno[acns]
# select only SNPs with minor allele frequecny above threshold
AC1 = G.sum(axis = 1)
AC0 = G.shape[1] - AC1
AC = np.vstack((AC0, AC1))
MAC = np.min(AC, axis = 0)
MAF = MAC/G.shape[1]
SNP_indices =  np.where(MAF >= float(args.maf))[0]
SNPs_MAF = MAF[SNP_indices]
G = G[SNP_indices, :]
print(f'Of the {acnNrInitial} phenotyped accessions, {len(acn_indices)} accessions were present in the SNP matrix.')
print(f'{len(SNP_indices)} SNPs had a minor allele frequency higher than {args.maf}')
# transpose G matrix into the required acccessions x SNPs format
G = G.transpose()

# Kinship (K)
kinFile = f'{args.genotype}/kinship_ibs_binary_mac5.h5py'
kin_hdf = h5py.File(kinFile, 'r')
# select kinship only for phenotyped and genotyped accessions
acn_indices = [np.where(kin_hdf['accessions'][:] == acn)[0][0] for acn in pheno.index]
acn_indices.sort()
K = kin_hdf['kinship'][acn_indices, :][:, acn_indices]
kin_hdf.close()

# get phenotype in correct order
pheno = pheno.loc[acn_order]
Y = pheno.to_numpy()

# Covariates (M)
if args.covariates:
  covars = pd.read_csv(args.covariates, index_col = 0)
  # TODO: test if limix can handle NAs. if so, make this optional
  # remove NA values
  covars = covars.dropna(axis = 0, how = 'any')
  # enocde covars.index to UTF8, for complemetarity with SNP matrix accessions
  covars.index = covars.index.map(lambda x: str(x).encode('UTF8'))
else:
  covars=None
  
# scan
r = scan(G, Y, K = K, lik = args.link, M = covars, verbose = True)

# save results
# Make sure the output directory exists
os.makedirs(args.outDir, exist_ok=True)
# link chromosome and positions to p-values and effect sizes
geno_hdf = h5py.File(genoFile, 'r')
chrIdx = geno_hdf['positions'].attrs['chr_regions']
chrom = [bisect(chrIdx[:, 1], snpIdx) + 1 for snpIdx in SNP_indices]
positions = geno_hdf['positions'][:]
pos = [positions[snp] for snp in SNP_indices]
pvalues = r.stats.pv20.tolist()
effsizes = r.effsizes['h2']['effsize'][r.effsizes['h2']['effect_type'] == 'candidate'].to_list() 
Bonferroni = multitest.multipletests(pvalues, alpha = 0.05, method = 'fdr_bh')[3]

gwas_tuples = list(zip(chrom, pos, pvalues))
gwas_results = pd.DataFrame(gwas_tuples, columns = ['chrom', 'pos', 'pv'])

# plot results
# Manhattan plot
plot.manhattan(gwas_results)
plt = plot.get_pyplot() 
_ = plt.axhline(-math.log(Bonferroni, 10), color='red')  
plt.savefig(f'{args.outDir}/manhattanPlot_{trait}_{args.maf}.png')
plt.close()

# QQ-plot
plot.qqplot(gwas_results.pv)
plt = plot.get_pyplot()
plt.savefig(f'{args.outDir}/qqPlot_{trait}_{args.maf}.png')
plt.close()

# Save results
gwas_results['maf'] = SNPs_MAF
gwas_results['mac'] = gwas_results.maf * len(acn_indices) 
gwas_results.mac = gwas_results.mac.astype(int)   
gwas_results['GVE'] = effsizes 
gwas_results.columns.values[0] = 'chr' 
gwas_results.columns.values[2] = 'pvalue'
gwas_results.to_csv(f'{args.outDir}/{trait}_{args.maf}.csv', index = False)
