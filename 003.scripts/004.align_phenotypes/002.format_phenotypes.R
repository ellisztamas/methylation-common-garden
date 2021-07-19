#' Tom Ellis, July 2021
#' 
#' Script to line up genome-wide average methylation values from 
#' `003.scripts/007.mean_mC_jobarray.sh` with the id of each sample from 
#' `003.scripts/004.align_phenotypes/001.get_plate_positions.py`.

# need to add bitacora data to this.
library(tidyverse)

meth_gw <- read_csv(
  "004.output/003.methylation_levels/mean_mC_genome_wide.csv",
  col_types = 'ccdddd'
) %>% 
  # remove sufffix and prefixes around file names so they can be matched to other files.
  mutate(file  = str_sub(file, 6, -8)) %>% 
  left_join(
    read_csv("004.output/002.link_samples/manually_check_snpmatch_results.csv", col_types = 'cccccccccdcccccccc'),
    by = 'file'
  ) %>% 
  filter(match %in% c("TRUE", "True", "Fine")) %>% 
  select(file, chr_type, id, lines, Site, plate, position, CG, CHG, CHH, coverage) %>% 
  rename(
    type = chr_type,
    genotype = lines,
    site = Site,
    tray_position = position
  ) %>% 
  mutate(type = ifelse(type == "autosomes", "genome-wide", type))

meth_tes <- read_csv("004.output/003.methylation_levels/mean_mC_TEs.csv", col_types = "ccddd")  %>% 
  # remove sufffix and prefixes around file names so they can be matched to other files.
  mutate(file  = str_sub(file, 6, -8)) %>% 
  left_join(
    read_csv("004.output/002.link_samples/manually_check_snpmatch_results.csv", col_types = 'cccccccccdcccccccc'),
    by = 'file'
  ) %>% 
  filter(match %in% c("TRUE", "True", "Fine")) %>% 
  select(file, TE_type, id, lines, Site, plate, position, CG, CHG, CHH) %>% 
  rename(
    type= TE_type,
    genotype = lines,
    site = Site,
    tray_position = position
  )

# Create a list of data frames.
mC <- list(
  meth_gw  %>% split(meth_gw$type),
  meth_tes %>% split(meth_tes$type)
) %>% 
  flatten()
names(mC) <- c("genome_wide", "organelles", "all_TEs", "CMT2", "RdDM")

# Add vectors for genome-wide sequence coverage for TEs
mC$all_TEs$coverage <- mC$genome_wide$coverage
mC$CMT2$coverage <- mC$genome_wide$coverage
mC$RdDM$coverage <- mC$genome_wide$coverage

# Sample 831 has apparent methylation levels > 0.9. Remove
mC <- lapply(mC, function(x) x %>% filter(CHH<0.8))

# Tidy extra tables
rm(meth_gw, meth_tes)