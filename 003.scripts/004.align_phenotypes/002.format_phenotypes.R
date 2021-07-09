#' Tom Ellis, July 2021
#' 
#' Script to line up genome-wide average methylation values from 
#' `003.scripts/007.mean_mC_jobarray.sh` with the id of each sample from 
#' `003.scripts/004.align_phenotypes/001.get_plate_positions.py`.

# need to add bitacora data to this.
library(tidyverse)

mean_mC <- read_csv(
  "004.output/003.methylation_levels/mean_mC_genome_wide.csv",
  col_types = 'cdddd'
) %>% 
  # remove sufffix and prefixes around file names so they can be matched to other files.
  mutate(file  = str_sub(file, 6, -8)) %>% 
  left_join(
    read_csv("004.output/002.link_samples/manually_check_snpmatch_results.csv", col_types = 'cccccccccdcccccccc'),
    by = 'file'
  ) %>% 
  filter(match %in% c("TRUE", "True", "Fine")) %>% 
  select(file, id, lines, Site, plate, position, CG, CHG, CHH, coverage) %>% 
  rename(
    genotype = lines,
    site = Site,
    tray_position = position
  )