# Tom Ellis
#
# Functions to calculate weighted-mean methylation on HDF5 files taken
# from an early draft of the common garden analyses.

import numpy as np
import pandas as pd
import h5py as h5
from os import listdir
from warnings import warn
from time import time, strftime
from pprint import pprint
from scipy.stats import binom

def weighted_mean_methylation(mc_class, mc_count, total, patterns=None):
    """
    Calculate mean methylation (weighted by coverage) on a chunk 
    of sequence from methylpy output.
    
    Parameters
    ----------
    mc_class: vector of strings
        Array of (byte) strings indicating a cytosine and the two
        following nucleotides in the format used in the attribute
        'mc_class' of methylpy HDF5 files.
    mc_counts: vector of integers
        Number of methylated reads mapping to each cytosine.
    total: vector of integers
        Number of total reads mapping to each cytosine.
    patterns: dict
        Dictionary of sequence contexts to compare. If `None`, the
        default is CG, CHG and CHH.
    
    Returns
    -------
    List of three dictionaries with entries for each sequence context:
    0. Number of reads mapping to methylated cytosines.
    1. Number of reads mapping to all cytosines.
    2. Number of cytosines in each sequence context.
    
    Example
    -------
    # Import an HDF5 file from the methylpy pipeline
    path = '/groups/nordborg/projects/cegs/rahul/014.fieldData/003.methylpy/002_3_fieldsamples_2019/hdf5/'
    filename = path + 'allc_CDN2BANXX_6#89662_ATGCGCAGrandom.hdf5'
    fle = h5.File(filename, 'r')
    
    # Get data for the first chunk.
    chunk_size = 1000
    start = 0
    stop  = start + chunk_size
    
    seq   = fle['mc_class'][start:stop]
    meth  = fle['mc_count'][start:stop]
    reads = fle['total'][start:stop]
    
    # Run the function on the first chunk
    weighted_mean_methylation(seq, meth, reads)
    
    # Example with different set of patterns splitting up CHH
    patterns = {
            "CHC" : [b'CAC', b'CGC', b'CTC'],
            "CHG" : [b'CAG', b'CGG', b'CTG'],
            "CHT" : [b'CAT', b'CGT', b'CTT']
        }
    weighted_mean_methylation(seq, meth, reads, patterns)
    """
    if patterns is None:
        patterns = {
            "CG"  : [b'CGA', b'CGC', b'CGG', b'CGT'],
            "CHG" : [b'CAG', b'CGG', b'CTG'],
            "CHH" : [b'CAA', b'CAG', b'CAT', b'CGA', b'CGG', b'CGT', b'CTA', b'CTG',b'CTT']
        }
    
    # Indices for each context
    ix = {k: np.isin(mc_class, v) for k,v in patterns.items()}
    
    meth   = {k : mc_count[v].sum() for k,v in ix.items()}
    total  = {k :    total[v].sum() for k,v in ix.items()}
    nC     = {k :          v .sum() for k,v in ix.items()}

    return [meth, total, nC]

def genome_wide_methylation(file, patterns=None, downsample=None):
    """
    Calculate average methylation over all cytosines in a genome, weighted
    by the number of reads mapping to each.
    
    This calculates the numerator and denominator of the weighted average
    function for each chunk in a genome, and adds them up at the end to
    claculate a single weighted average.
    
    Parameters
    ----------
    file: HDF5
        Chunked file from the methylpy pipeline giving at least the
        following attributes:
        1. `mc_class`: Vector of strings giving cytosines and the next two 
            nucleotides.
        2. `mc_count`: Vector of integers giving the number of methylated 
            reads mapping to each cytosine.
        3. `total`: Vector of integers giving the number of reads mapping to
            each cytosine.
        4. `chunk_size`: Size of each chunk. Integer.
        5. `pos`: Vector of coordinate positions for each cytosine.
    patterns: dict
        Dictionary of sequence contexts to compare. If `None`, the
        default is CG, CHG and CHH.
    downsample: float between 0 and 1
        Optional proportion by which to downsample reads. Methylated and
        unmethylated reads will be sampled from a binomial distribution with
        *n* as the number of observed reads and p as this proporiton.
    
    Returns
    -------
    Dictionary with an entry for each sequence context. Each dictionary returns:
    0. Number of reads mapping to methylated cytosines (product of 
        methylation status and number of reads mapping to each cytosine).
    1. Number of reads mapping to each cytosine.
    2. Number of cytosines in each sequence context.
    
    Examples
    --------
    # Import an HDF5 file from the methylpy pipeline
    path = '/groups/nordborg/projects/cegs/rahul/014.fieldData/003.methylpy/002_3_fieldsamples_2019/hdf5/'
    filename = path + 'allc_CDN2BANXX_6#89662_ATGCGCAGrandom.hdf5'
    fle = h5.File(filename, 'r')
    
    genome_wide_methylation(fle)
    
    # Example with different set of patterns splitting up CHH
    patterns = {
            "CHC" : [b'CAC', b'CGC', b'CTC'],
            "CHG" : [b'CAG', b'CGG', b'CTG'],
            "CHT" : [b'CAT', b'CGT', b'CTT']
    }
    genome_wide_methylation(fle, patterns)
    """
    if patterns is None:
        patterns = {
            "CG"  : [b'CGA', b'CGC', b'CGG', b'CGT'],
            "CHG" : [b'CAG', b'CGG', b'CTG'],
            "CHH" : [b'CAA', b'CAG', b'CAT', b'CGA', b'CGG', b'CGT', b'CTA', b'CTG',b'CTT']
        }
    # Book keeping for HDF5 files.
    start = 0
    end = file['pos'].shape[0]
    chunk_size = file['chunk_size'][0]

    # Empty dictionaries to store output for each chunk on
    # Methylated sites * number of reads
    # Number of reads
    # Number of cytosines.
    mean_mC = nreads = nC = {k:0 for k in patterns.keys()}

    # Run weighted_mean_methylation() on each chunk.
    for i in range(start, end, chunk_size):
        stop_i = np.min([i + chunk_size, end])
        # Import a chunk
        seq =  file['mc_class'][start:stop_i]
        meth = file['mc_count'][start:stop_i]
        w =    file['total'][start:stop_i]
        
        # # If there is downsampling to be done, subsample methylated and unmethylated reads.
        if downsample:
            if (downsample > 1) or (downsample < 0):
                raise ValueError("downsample should be between zero and one.")
            new_unmeth = binom.rvs(w - meth, p=downsample)
            meth = binom.rvs(meth, p=downsample)
            w = meth + new_unmeth
            
        # Get weighted mean methylation for this chunk
        chunk_meth = weighted_mean_methylation(
            mc_class = seq, 
            mc_count = meth, 
            total = w,
            patterns = patterns
        )

        # Send results to output dictionaries
        mean_mC = {k: mean_mC[k] + chunk_meth[0][k] for k in patterns.keys()}
        nreads  = {k: nreads[k]  + chunk_meth[1][k] for k in patterns.keys()}
        nC      = {k: nC[k]      + chunk_meth[2][k] for k in patterns.keys()}
    
    output = [
        {k: mean_mC[k] / nreads[k] for k in patterns.keys()}, # weighted mean methylation
        nreads,
        nC
    ]
    return output

def sliding_window_methylation(file, window_size, patterns=None, downsample=None):
    """
    Sliding window quantification of methylation across a single genome

    Parameters
    ----------
    file: HDF5
        Chunked file from the methylpy pipeline giving at least the
        following attributes:
        1. `mc_class`: Vector of strings giving cytosines and the next two 
            nucleotides.
        2. `mc_count`: Vector of integers giving the number of methylated 
            reads mapping to each cytosine.
        3. `total`: Vector of integers giving the number of reads mapping to
            each cytosine.
        4. `chunk_size`: Size of each chunk. Integer.
        5. `pos`: Vector of coordinate positions for each cytosine.
    window_size: int
        Width of the window in nucleotides
    patterns: dict
        Dictionary of sequence contexts to compare. If `None`, the
        default is CG, CHG and CHH.
    downsample: float between 0 and 1
        Optional proportion by which to downsample reads. Methylated and
        unmethylated reads will be sampled from a binomial distribution with
        *n* as the number of observed reads and p as this proporiton.

    Returns
    -------
    A CSV file with rows indexing windows giving:
    1. filename of the HDF5 file
    2. A string showing chomosome and first and last cytosines in the window
    3. weighted mean methylation
    4. number of reads mapping to cytosines in the window
    5. total number of cytosines in the window.

    Examples
    --------
    # Import an HDF5 file from the methylpy pipeline
    path = '/groups/nordborg/projects/cegs/rahul/014.fieldData/003.methylpy/002_3_fieldsamples_2019/hdf5/'
    filename = path + 'allc_CDN2BANXX_6#89662_ATGCGCAGrandom.hdf5'
    fle = h5.File(filename, 'r')

    genome_wide_methylation(fle)

    # Example with different set of patterns splitting up CHH
    patterns = {
            "CHC" : [b'CAC', b'CGC', b'CTC'],
            "CHG" : [b'CAG', b'CGG', b'CTG'],
            "CHT" : [b'CAT', b'CGT', b'CTT']
    }
    genome_wide_methylation(fle, patterns)
    """
    if patterns is None:
        patterns = {
            "CG"  : [b'CGA', b'CGC', b'CGG', b'CGT'],
            "CHG" : [b'CAG', b'CGG', b'CTG'],
            "CHH" : [b'CAA', b'CAG', b'CAT', b'CGA', b'CGG', b'CGT', b'CTA', b'CTG',b'CTT']
        }
    # Book keeping for HDF5 files.
    start = 0
    end = file['pos'].shape[0]

    # Label each site with a window bin.
    window = pd.cut(
        file['pos'][()],
        bins = np.arange(0, file['pos'][()].max(), window_size)
    )

    output = []
    for cx in [b'Chr1', b'Chr2', b'Chr3', b'Chr4', b'Chr5']:
        for wx in window.categories:
            pos_label = cx.decode() + "_" + str(wx).split(',')[0][1:] + "_" + str(wx).split(',')[1][1:-1]
                
            ix = (window == wx) & (file['chr'][()] == cx)
            ix = list(np.where(ix)[0])
            
            # If there is at least one cytosine in the bin calculate mean methylation
            if len(ix) > 0:
                # Run weighted_mean_methylation() on each window.
                # Import a chunk
                seq =  file['mc_class'][ix]
                meth = file['mc_count'][ix]
                w =    file['total'][ix]
                # Get weighted mean methylation for this chunk
                this_window = weighted_mean_methylation(
                    mc_class = seq, 
                    mc_count = meth, 
                    total = w,
                    patterns = patterns
                )

                o = [[pos_label, k, this_window[0][k], this_window[1][k], this_window[2][k]] for k in patterns.keys()]
                output.append(
                    pd.DataFrame(o, columns= ['pos','context', 'mean_meth', 'nreads', 'nC'])
                )
            # If there are no methylated cytosines, return zeros.
            else:
                output.append(
                    pd.DataFrame({
                        'pos': pos_label,
                        "context" : list(patterns.keys()),
                        "mean_meth" : 0,
                        "nreads" : 0,
                        "nC" : 0
                    })
                )

    return pd.concat(output)

def compile_methylation(input_folder, output_folder, patterns = None, downsample = None):
    """
    Calculate mean methylation for each genome in a folder of HDF5 files.
    
    Parameters
    ----------
    input_folder: str
        Folder where HDF5 files are to be found.
    output_folder: str
        Folder where data are to be saved.
    patterns: dict
        Dictionary of sequence contexts to compare. If `None`, the
        default is CG, CHG and CHH.
    downsample: float between 0 and 1
        Optional proportion by which to downsample reads. Methylated and
        unmethylated reads will be sampled from a binomial distribution with
        *n* as the number of observed reads and p as this proporiton.
        
    Returns
    -------
    Returns separate CSV files for each sequence context with a row for 
    each sample listing:
    1. Sample label
    2. Weighted mean methylation across the genome
    3. Total number of reads mapping to each cytosine.
    4. Total number of cytosines
    """
    if output_folder[-1] != "/":
        output_folder = output_folder + "/"
        warn("output_folder did not end with a '/'. This will be added automatically.")
        
    if patterns == None:
        patterns = {
            "CG"  : [b'CGA', b'CGC', b'CGG', b'CGT'],
            "CHG" : [b'CAG', b'CGG', b'CTG'],
            "CHH" : [b'CAA', b'CAG', b'CAT', b'CGA', b'CGG', b'CGT', b'CTA', b'CTG',b'CTT']
        }
    
    print('Quantification of genome-wide methylation begun {}'.format(strftime("%Y-%m-%d %H:%M:%S")),
          'files in the input folder:\n',
          '{}\n'.format(input_folder))
    print('Looking for methylation in the following sequence contexts:\n')
    print(patterns)
    
    # Empty lists to store methylation data in each context.
    output = {k: [] for k in patterns.keys()}

    # List of files to iterate over
    files = listdir(input_folder)
    
    print('\n\nProcessing genome for:\n')
    for filename in files:
        print('{}\n'.format(filename))
        
        if not filename.endswith('.hdf5'):
            warn("The current file is not an HDF5 and will be skipped: {}\n".format(filename))

        # Load the HDF5 file.
        pathname = input_folder + filename
        fle = h5.File(pathname, 'r')

        # Genome wide methylation for this genome
        this_meth = genome_wide_methylation(fle, patterns, downsample)
        # Transpose this_meth to use sequence context as a key.
        this_meth = {k: [filename, this_meth[0][k], this_meth[1][k], this_meth[2][k]] for k in patterns.keys()}
        # Send results to output.
        for k in patterns.keys():
            output[k] = output[k] + [this_meth[k]]
        
        fle.close()
            
    print('Analyses complete. Writing to the following output folder:\n{}'.format(output_folder))
    
    # Glue together and write to disk.
    for k in output.keys():
        this_file = pd.DataFrame(output[k], columns = ['sample', 'mean_meth', "nreads", "nC"])
        this_file.to_csv(output_folder + "genomewide_" + k + ".csv", index=False)
    
    print('\nCompleted {}.\n'.format(strftime("%Y-%m-%d %H:%M:%S")))