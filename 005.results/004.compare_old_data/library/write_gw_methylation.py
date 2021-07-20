from argparse import ArgumentParser
from meth_from_wma_araport import *
from os.path import basename

parser = ArgumentParser(description = "Parse parameters for weighted-mean methylation over a whole genome")
parser.add_argument("-f", "--filename",  help="Input HDF5 file.")
parser.add_argument("-o", "--output", help="Folder to output results.")
parser.add_argument("-d", "--downsample", help="Optional proportion by which to downsample reads.", type=float, required=False)
args = parser.parse_args()

if args.output[-1] != "/":
    args.output = args.output + "/"
    # warn("output did not end with a '/'. This will be added automatically.")

if not args.filename.endswith('.hdf5'):
    warn("The current file is not an HDF5 and will be skipped: {}\n".format(filename))

# Load the HDF5 file.
fle = h5.File(args.filename, 'r')

# Genome wide methylation for this genome
patterns = {
    "CG"  : [b'CGA', b'CGC', b'CGG', b'CGT'],
    "CHH" : [b'CAA', b'CAG', b'CAT', b'CGA', b'CGG', b'CGT', b'CTA', b'CTG',b'CTT'],
    # "CHA" : [b'CAA', b'CCA', b'CTA'],
    # "CHC" : [b'CAC', b'CCC', b'CTC'],
    "CHG" : [b'CAG', b'CCG', b'CTG']
    # "CHT" : [b'CAT', b'CCT', b'CTT']
    }
this_meth = genome_wide_methylation(fle, patterns = patterns, downsample = args.downsample)
# Transpose this_meth to use sequence context as a key.
this_meth = {k: [basename(args.filename), this_meth[0][k], this_meth[1][k], this_meth[2][k]] for k in patterns.keys()}

# Transpose
output = pd.DataFrame(
    list(this_meth.values()),
    columns=['filename', 'mean_meth', 'nreads', 'nC']
)
output.insert(1, 'context', this_meth.keys())
# Write to disk
output.to_csv(
    args.output + 'genomewide_' + basename(args.filename).split('.')[0] + ".csv",
    index=False,
    header=False
)

fle.close()