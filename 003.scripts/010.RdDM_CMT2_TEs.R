# Tom Ellis, July 2021, modifying code by Eriko Sasaki
#
# This takes files created by `003.scripts/009.methylation_on_TEs.sh`
# and average over TEs in the genome. It returns a table with 3 rows
# for each sample showing mean methylation on all TEs, RdDM- and CMT2-
# targetted TEs, with columns for CG, CHG and CHH sequence contexts.

library(tidyverse)

# Vectors of TEs known to be targetted by RdDM and CMT2.
CMT2=read_csv(
  '001.data/001.raw/003.genome_annotations/CMT2_target_TEs.txt',
  col_names = FALSE) %>%
  pull(X1)
RdDM=read_csv(
  '001.data/001.raw/003.genome_annotations/RdDM_target_TEs.txt', 
  col_names = FALSE) %>% 
  pull(X1)

DatDir='004.output/003.methylation_levels/reads_on_each_TE/'
OutDir='004.output/003.methylation_levels/'
FList=list.files(DatDir)

CHH=NULL
CHG=NULL
CG=NULL
for(File in FList){
	D=read.table(paste(DatDir, File, sep=""), row.names=1, header=TRUE)
	rCHH=round(D$mCHH / D$cCHH, 3)
	CHH=cbind(CHH, rCHH)
	rCHG=round(D$mCHG / D$cCHG, 3)
	CHG=cbind(CHG, rCHG)
	rCG=round(D$mCG / D$cCG, 3)
	CG=cbind(CG, rCG)
}

rownames(CHH)=rownames(D)
rownames(CHG)=rownames(D)
rownames(CG)=rownames(D)

colnames(CHH)=FList
colnames(CHG)=FList
colnames(CG)=FList

output <- rbind(
  # Methylation on all annotated TEs.
  data.frame(
    file = data.frame(FList),
    TE_type = "all",
    CG  = CG  %>% colMeans(na.rm = TRUE),
    CHG = CHG %>% colMeans(na.rm = TRUE),
    CHH = CHH %>% colMeans(na.rm = TRUE)
  ),
  # CMT2-targetted TEs
  data.frame(
    file = data.frame(FList),
    TE_type = "CMT2",
    CG  = CG[CMT2,]  %>% colMeans(na.rm = TRUE),
    CHG = CHG[CMT2,] %>% colMeans(na.rm = TRUE),
    CHH = CHH[CMT2,] %>% colMeans(na.rm = TRUE)
  ),
  # RdDM-targetted TEs
  data.frame(
    file = data.frame(FList),
    TE_type = "RdDM",
    CG  = CG[RdDM,]  %>% colMeans(na.rm = TRUE),
    CHG = CHG[RdDM,] %>% colMeans(na.rm = TRUE),
    CHH = CHH[RdDM,] %>% colMeans(na.rm = TRUE)
  )
)

write_csv(
  output,
  path = paste(OutDir, 'mean_mC_TEs.csv', sep="")
  )