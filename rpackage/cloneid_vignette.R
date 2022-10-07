library(cloneid)
cloneid::setupCLONEID(host='localhost',  user='XX', password='YY'); 

## Add cellLine & sample(s) to SQL database:
cellLine <- lineageId <- "SNU-16"
addSampleSources(cellLine)
init(lineageId, cellLine, cellCount=1E9)

## Load genome and transcriptome data:
data(CloneProfiles)

## Write input for viewPerspective():
setwd("~/Downloads")
for(y in names(CloneProfiles)){
  dir.create(y)
  for (x in names(CloneProfiles[[y]])){
    write.table(CloneProfiles[[y]][[x]], file = paste0(y,filesep,x), sep = "\t", quote = F, row.names = F)
  }
}

## add Transcriptome Perspective to SQL database:
outT = viewPerspective(spstatsFile ="~/Downloads/TranscriptomePerspective/SNU-16.spstats",  suffix=".sps.cbs", whichP="TranscriptomePerspective")

## add Genome Perspective to SQL database:
outG = viewPerspective(spstatsFile ="~/Downloads/GenomePerspective/SNU-16.spstats", suffix=".sps.cbs", whichP="GenomePerspective")


## Merge perspectives
out=merge(perspective1="GenomePerspective", perspective2="TranscriptomePerspective", "SNU-16")

out$sp2clone_sim 

out$sp2clone

