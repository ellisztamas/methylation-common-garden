"""
Tom Ellis, modifying code by Rahul Pisupati, 7th June 2021.

Script to link filenames of BAM files with positions on each plate.
Each position in a well plate corresponds to unique combination of 
forward and backward adapter sequences, which are contained in JSON
files.

There is currently an issue that plate 145 (flowcell CDN2BANXX) uses a 
different indexing system to the others. This script exports a file
for that well only, and I then lined names up manually.
"""

import glob
import pandas as pd
import os
import json

os.chdir("/users/thomas.ellis/common_gardens/")

# Import SNPmatch results
snp_match = pd.read_csv("004.output/001.snpmatch/intermediate_modified.csv", dtype=str).\
rename(columns = {'Unnamed: 0' : 'file'}).\
set_index('file')
# Reformat filenames in SNPmatch results
snp_match.index = [x[2] for x in snp_match.index.str.split(".")]

# Import file mapping barcodes to positions within ecah plate
indices = pd.read_csv("001.data/001.sequencing/003.plating_files/NGS_index_sets_long.csv", dtype=str)
# Import field experiment master list
master_list = pd.read_csv(
    "001.data/001.sequencing/003.plating_files/common_garden_genotyping_master_list.csv", dtype=str
).\
filter(items = ['label', 'lines', 'Site', 'position']).\
merge(
    pd.read_csv("001.data/001.sequencing/003.plating_files/sequencing_plates.csv"),
    left_on='label', right_on='id', how='right'
).astype(str)

# Path to raw unzipped bam files.
path="/users/thomas.ellis/common_gardens/001.data/001.sequencing/002.unzipped_bams/1*/"

# List of bam files stores as a Pandas series
bam_files = glob.glob( path + "*bam" )
bam_files = pd.Series( bam_files ).apply( os.path.basename )
# Pull out JSON files with meta data on each sample
json_file = glob.glob( path + "*barcodes.json" )
json_barcode = []
for ef in json_file:
    with open(ef, 'r') as json_out:
        json_barcode += json.load(json_out)
# empty dataframe
sample_csv = (pd.DataFrame({'index':bam_files}).
 append({'seqlane_id':'','row_id':'', 'col_id':'', 'barcode_set':''}, ignore_index=True).
 set_index('index')
)
sample_csv = sample_csv.loc[pd.notna(sample_csv.index)]
# Fill in sample_csv with data from JSON files
for ef in range(len(json_barcode)):
    t_lane_id = str(json_barcode[ef]['vendor_id']) + "_" + str(json_barcode[ef]['unit_id']) + "#"
    sample_barcode = t_lane_id + str(json_barcode[ef]['sample_id']) + '_' + json_barcode[ef]['adaptor_tag'] + json_barcode[ef]['adaptor_secondary_tag']
    t_index = sample_csv.index[sample_csv.index.str.contains( sample_barcode )]
    if len(t_index) > 1:
        print("Caution!!!")
    else:
        sample_csv.loc[t_index, "col_id"] = str(json_barcode[ef]['adaptor_secondary_number'])
        sample_csv.loc[t_index, "row_id"] = str(json_barcode[ef]['adaptor_number'])
        sample_csv.loc[t_index, "barcode_set"] = json_barcode[ef]['adaptor_type']
        sample_csv.loc[t_index, "seqlane_id"] = t_lane_id# str(json_barcode[ef]['vendor_id'])# + "_" + str(json_barcode[ef]['unit_id'])
# Tidy up sample names and barcode sets.
sample_csv.index = sample_csv.index.str.replace(".bam$", "")
sample_csv['barcode_set'] = sample_csv['barcode_set'].\
str.replace( "Nordborg Nextera INDEX set", "" ).\
str.replace( "Nextera XT", '0' ).\
astype(int)

# Merge sample_csv with positions in a plate
sample_csv  = sample_csv.\
reset_index().rename(columns = {'index': 'file' }).\
merge(
    pd.read_csv("001.data/001.sequencing/003.plating_files/NGS_index_sets_long.csv", dtype=str),
    how = "left", on = ['row_id', 'col_id']
).\
sort_values(by = ['seqlane_id', 'COL', 'ROW']).\
set_index("file").\
sort_values(['seqlane_id', 'row_id'])

# Add plate labels
sample_csv['plate'] = ''
sample_csv['plate'].loc[sample_csv.index.str.contains("CDN24ANXX")]  = '144'
sample_csv['plate'].loc[sample_csv.index.str.contains("CDN2BANXX")]  = '145'
sample_csv['plate'].loc[sample_csv.index.str.contains("115306")] = '167'
sample_csv['plate'].loc[sample_csv.index.str.contains("128708")] = '168'
sample_csv['plate'].loc[sample_csv.index.str.contains("128709")] = '169'

# Check there are 96 samples for each plate
assert all([(sample_csv['plate'] == x).sum() == 96 for x in ['144', '145', '167', '168', '169']])
# # Check no samples are missing a plate label.
assert sample_csv['plate'].isin(['144', '145', '167', '168', '169']).all()

# Merge sample_csv with master list to line up intended genotype with
# results from SNPmatch.
sample_csv.\
merge(snp_match, how="right", left_index=True, right_index=True).\
filter(items = ['row_id','seqlane_id', 'plate', 'ROW', 'COL', 'TopHitAccession','NextHit', 'ThirdHit', 'Score']).\
reset_index().rename(columns = {'index' : 'file'}).\
merge(
    master_list,
    how = 'left',
    left_on= ['plate', 'ROW', 'COL'], right_on = ['plate','row', 'col']
).\
sort_values(['plate', 'seqlane_id', 'COL', 'ROW']).\
assign(match = lambda x: (x.lines == x.TopHitAccession) | (x.lines == x.NextHit) | (x.lines == x.ThirdHit)).\
to_csv("004.output/manually_check_snpmatch_results_tmp.csv")

# # Create a seprate file for plate 145 to be edited manually.
# master_list.loc[master_list['plate'] == '145'].\
# sort_values(['col', 'row']).\
# to_csv("004.output/plate145.csv", index=False)