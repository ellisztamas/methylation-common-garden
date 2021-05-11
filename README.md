# Methylation variation in common garden experiments

Tom Ellis

A project investigating the genetic, environmental, and GxE components of methylation variation in *Arabidopsis thaliana* plants grown in common garden experiments in Sweden.

Paths in this README refer either to relative paths within this repository, or else to absolute paths in the GMI high-performance-computing cluster.

## Table of contents

1. [Experimental set up](#experimental-set-up)
3. [Data](#data-files)
    * [Field data](#field-data)
    * [Sequencing data](#sequencing-data)
4. [Dependencies](#dependencies)
5. [Author information](#author-information)


## Experimental set up

This project coopts an experiment set up by Daniele Filiault, Ben Brachi and others investigating the genetic basis of local adaptation in *A. thaliana*. See `/groups/nordborg/projects/field_experiments/` for details of that project.

Briefly, 200 Swedish accessions were grown at four sites at the High Coast (Ramsta, Adal) and Skåne (Rathkegården, Ullstorp) in Sweden with (I think) 24 plants per accession per site, in two years. In Autumn 2012, Polina Novikova, Fernanda Rabanal and Manu Dubin drove to each site to harvest tissue from between one and 6 plants per accession per site. They collected whole rosettes, rinsed briefly with water, dried with paper towel, wrapped in foil envelopes and placed on dry ice. I found notes about this project from various people on [Google drive](https://drive.google.com/drive/folders/0B2_HB0VI2ORrWVRGLU0wcm5YMVE), including a [collection schedule](https://drive.google.com/drive/folders/0B2_HB0VI2ORrWVRGLU0wcm5YMVE). I saved a snapshot of this folder to `006.reports/001.notes_from_google_drive/` for posterity.

Notes kept on *eLabJournal* about this projects are [here](https://vbc.elabjournal.com/members/experiments/browser/#view=study&nodeID=45911&page=0&userID=20538&status=0&column=created&order=DESC&search=) under the project `epiclines/Common gardens`.

## Data

### Field data

A table explaining what samples were collected in the field is given in `/001.data/001.raw/common_garden_genotyping_master_list.csv`. I inherited this from google drive, and it appears to have been written by the field sampling team. I couldn't find an explicit explanation of the columns, but I think they are:
    
1. label: Unique identifier for each plant sampled. Use this to link up plants with sequencing data.
2. tubes: I don't know what this is.
3. tray: Tray ID from Daniele's experiment
4. position: row and column of the plant witin the tray, separated by a dot (trays have 11 rows and 6 columns)
5. observations_for_sampling: Note taken about the sample
6. Site: Experimental site
7. Location: Region of the experimental site.
8. original: I don't know what this is.
9. score.x: I don't know what this is.
10. set: I don't know what this is.
11. lines: Numerical accession code.
12. name: Long-format accession name
13. region: Region of Sweden from which the accession originates.

For phenotypic data collected from these experiments, please see Daniele Filiault's main project about this experiment at `/groups/nordborg/projects/field_experiments/`.

### Sequencing data

There are two sequencing datasets, which overlap:

1. **Intensive sample** ([plates 144 and 145](https://docs.google.com/spreadsheets/d/1gX_zYZMaFUk6SMOYTfcjOlv9Mv5vv6ksmSUq_iSSVnU/edit#gid=0))
    * 12 accessions from all four sites, using as many replicates per accession per site as were available.
    * This is intended to allow us to partition variance in matheylation into genetic, enviromental, GxE and residual-noise components.
    * This was done before I arrived, so see Ilka's note at `006.reports/001.notes_from_google_drive/Experimental setup.docx`.
2. **Extensive sample** ([plates 167 to 171](https://docs.google.com/spreadsheets/d/1gX_zYZMaFUk6SMOYTfcjOlv9Mv5vv6ksmSUq_iSSVnU/edit#gid=0))
    * 1 replicate per accession per site at Adal and Rathkegården only for each of all 200 accessions.
    * This is intended as a panel for mapping genetic variants associated with methylation.
    * See notes on [*eLabJournal*](https://vbc.elabjournal.com/members/experiments/browser/#view=experiment&nodeID=227439) for how I did this.

#### Raw bisulphite data

Raw data are currently in `/groups/nordborg/projects/nordborg_rawdata/Athaliana/bisulfite_seq/field_data_from_2012` but will need moving to `/groups/nordborg/raw.data` at some point.

* Plate 144 is divided into four files:
    * CDN24ANXX_2_M8584.zip
    * CDN24ANXX_3_M8585.zip
    * CDN24ANXX_4_M8587.zip
    * CDN24ANXX_5_M8588.zip
* Plate 145 is divided into four files:
    * CDN2BANXX_1_M8246.zip
    * CDN2BANXX_4.zip
    * CDN2BANXX_5.zip
    * CDN2BANXX_6.zip
* Plate 167: `elxRjzjh9h-HKKWJDRXX_20200415B_demux_2_R9456.zip`
* Plate 168: `anQaf5Iadx-HMYF5DRXX_20200928B_demux_1_R10191.zip`
* Plate 169: `Tjpak3IDx6-HMYF5DRXX_20200928B_demux_2_R10191.zip`

CHECK THESE ONCE SNPMATCH IS DONE!

#### Processed sequencing data

The following steps to process raw reads are carried out:

1. Rahul Pisupati's fork of the [methylseq](https://github.com/rbpisupati/methylseq) pipeline to process bam files into methylation calls.
2. [nf-haplocaller](https://github.com/Gregor-Mendel-Institute/nf-haplocaller) to call genotypes based on a matrix of known variable sites
    * Note: We had to change [line 80](https://github.com/Gregor-Mendel-Institute/nf-haplocaller/blob/5c78ec474d728a277eebc2bd8b365bb5841155f7/snps_bsseq.nf#L80) from:
    ```python $workflow.projectDir/scripts/epidiverse_change_sam_queries.py```
    to
    ```/users/thomas.ellis/.conda/envs/snpcall/bin/python $workflow.projectDir/scripts/epidiverse_change_sam_queries.py```
    because conda was calling python from outside the conda environment. This needs fixing.
* [SNPmatch](https://github.com/Gregor-Mendel-Institute/SNPmatch) to compare genotypes to the 1001 genomes database to check plants are what we think they should be. I used the [nextflow pipeline](https://github.com/rbpisupati/nf-snpmatch) to run SNPmatch on each sample.
* The function `call-methylation-state` from [methylpy](https://github.com/yupenghe/methylpy) to generate `.allc` files for each sample. 

Each of these steps has a folder in `/003.scripts/` detailing what was done to each sequencing plate. These operate on the VBC-cluster node `scratch-cbe` for speed, and copy the output to `/001.data/002.processed/`.

## Dependencies

### Processing raw reads

* [methylseq](https://github.com/rbpisupati/methylseq)
* [nf-haplocaller](https://github.com/Gregor-Mendel-Institute/nf-haplocaller)
* [Nextflow pipeline for SNPmatch](https://github.com/rbpisupati/nf-snpmatch)
* [methylpy](https://github.com/yupenghe/methylpy)

### R
This project uses `renv` to ensure package versions match between machines. Open the project file `virus_resistance.Rproj` in the root directory of this project into RStudio (it won't work through the terminal!) and run `renv::refresh()`, and `renv` should automatically set up a local environment with the same package versions as were used to create the results. See the very good documentation on `renv` for more: https://rstudio.github.io/renv/articles/renv.html.

## Author information

* This folder is written and maintained by Tom Ellis
* Field work:
    * Daniele Filiault
    * Benjamin Brachi
    * Svante Holm
    * Magnus Nordborg
    * Fernando Rabanal
    * Polina Novikova
    * Manu Dubin
* Lab work:
    * Ilka Reichhardt-Gomez
    * Almudena Mollá Morales
    * Viktoria Nizhynska

Thanks to Rahul Pisupati for help with the bioinformatics.
