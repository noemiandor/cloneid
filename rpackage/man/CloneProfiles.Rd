\name{CloneProfiles}
\alias{CloneProfiles}
\docType{data}
\title{Data formatting example for clonal decompositions}
\description{Clonal profiles called from scRNA sequencing data of the SNU-16 stomach cancer cell line. Data structure describes input format for function @viewPerspective().}
\usage{data(CloneProfiles)}
\format{
List with keys denoting file names and values denoting file contents expected by @viewPerspective(). \cr

	Clonal profiles are given at two layers of cellular resolution: first layer contains subpopulations of cells (i.e. clones); second layer contains members (e.g. cells) assigned to each layer 1 subpopulation. Both layers are represented in the list. Entries are as follows:\cr \cr
  \bold{SNU-16.spstats} - layer 1 data.frame with each row denoting a subpopulation and columns denoting their IDs and cellular fractions \cr \cr
  \bold{SNU-16.sps.cbs} - layer 1 data.frame with each row denoting a genome feature (e.g. gene or copy number segment) and first column "LOCUS" denoting the name of that feature. Each additional column denotes the name of a subpopulation. Subpopulation names must include their respective cellular fraction as listed in SNU-16.spstats. \cr \cr
  \bold{SNU-16.0.0978009.sps.cbs} - optional. Layer 2 data.frame mapped to the name of the respective layer 1 subpopulation. Each row denotes a genome feature and first column "LOCUS" denotes the name of that feature. Each additional column denotes the name of a member from the respective layer 1 subpopulation. \cr \cr
  \bold{SNU-16.0.1066227.sps.cbs} - optional. same as above, but for a different subpopulation \cr \cr
  \bold{SNU-16.0.1212664.sps.cbs} - optional. same as above, but for a different subpopulation \cr \cr
  \bold{SNU-16.0.1243724.sps.cbs} - optional. same as above, but for a different subpopulation \cr \cr
  \bold{SNU-16.0.1506865.sps.cbs} - optional. same as above, but for a different subpopulation \cr \cr
  \bold{SNU-16.0.1914997.sps.cbs} - optional. same as above, but for a different subpopulation \cr \cr
  \bold{SNU-16.0.2122133.sps.cbs} - optional. same as above, but for a different subpopulation.
}

\keyword{datasets}

\examples{
## Memory needed to save single-cell data into SQL database
options(java.parameters = "-Xmx7g")

load('~/Downloads/CloneProfiles.rda');
names(CloneProfiles)
sapply(CloneProfiles, dim)
print(CloneProfiles$`SNU-16.spstats`)

## Layer 1:
head(CloneProfiles[['SNU-16.sps.cbs']])

## Layer 2:
head(CloneProfiles[['SNU-16.0.1914997.sps.cbs']])[,1:5]

## Compare rows and columns between layer1 and layer2:
i2 = grep("SNU-16.0.", names(CloneProfiles), value=T)
sapply(CloneProfiles[i2], function(layer2) intersect(layer2$LOCUS, CloneProfiles[['SNU-16.sps.cbs']]$LOCUS))
for (clone in CloneProfiles$`SNU-16.spstats`$`Mean Weighted`){
  f = substr(as.character(clone), 1,8)
  print(paste("Profile for clone", clone, "is in column", grep(f, colnames(CloneProfiles$`SNU-16.sps.cbs`), value = T),"of entry 'SNU-16.sps.cbs'" ))
  print(paste("Members of clone", clone, "are in entry", grep(f, names(CloneProfiles), value = T) ))
}

## Save input for viewPerspective()
# setwd("~/Downloads")
# for (x in names(CloneProfiles)){
#   write.table(CloneProfiles[[x]], file = x, sep = "\t", quote = F, row.names = F)
# }

## Run viewPerspective() to add to SQL database:
# viewPerspective(pathToSample="~/Downloads/SNU-16.spstats", clonesDIR="~/Downloads", suffix=".sps.cbs", whichP="TranscriptomePerspective")

}
