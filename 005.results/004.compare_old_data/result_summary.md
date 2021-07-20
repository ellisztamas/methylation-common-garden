# Result name

**Date:** 20th July 2021
**Author:** Tom Ellis

## Background
I am repeating the low-level bioinformatics on data from the common gardens. They look quite different to what I generated last year, so I am running the old script and new scripts on the same data.

Rahul generated folders with `allc` and (some kind of) `HDF5` files here in 2019:
```/groups/nordborg/projects/cegs/rahul/014.fieldData/003.methylpy/002_3_fieldsamples_2019```

I repeated mapping bams and have allc files here:
```004.output/001.methylseq/methylpy/```

## What did you do?
**tl;dr**:

1. I ran my **new script** on both sets of allc files
2. I ran **old scripts** on Rahul's HDF5 files.

The new script is `002.library/python/weighted_mean_mC_from_allc.py`
The old scripts are copied to this results folder in `library`.

## Main conclusion

Running the new script on the two data sets gives strongly, but not perfectly, correlated genome-wide average methyation. The difference could be due to difference in the pipeline to align bams.

## Caveats

## Follow-up
