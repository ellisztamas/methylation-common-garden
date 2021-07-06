# Result name

**Date:** 6th July 2021
**Author:** Tom Ellis

## Background

We have bisulphite data on (1) <=6 reps for 12 accessions at all sites and (2) one rep from all 200 accession from two sites. At the same time Rahul has found a batch effect for CHH methylation in his crosses, which might be biological or artefactual.

We want to know whether differences in CHH methylation can be due to differences between sequencing plates, environmental differences of where the plants were grown, or artefacts of sampling.

## What did you do?

`data-exploration.Rmd` examines distributions of methylation contexts and covariance between them.

## Main conclusion

There is increased variance in CHH methylation in plate 167 which is only apprarent when you plot the covariance with CHG methylation. Plate 167 tends to contain samples from Adal harvested on 20th October 2012, but the grouping for these variables is less black and white than the grouping by plate, suggesting that it is the effect of plate that is to blame. We cannot tell whether this is because of how I handled tissue at plating, or something to do with sample preparation.

## Caveats

## Follow-up
