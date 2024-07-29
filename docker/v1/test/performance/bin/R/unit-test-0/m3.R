library(cloneid)
library(tictoc)

getSubProfilesX <-function(x){
  print(paste("Processing:", x, extractID(x)))
  cloneid::getSubProfiles(cloneID_or_sampleName = as.numeric(extractID(x)), whichP = "GenomePerspective")
}

setupCLONEID(host='sql2', port='3306', user='root', password='xxxxx', database='CLONEID', schemaScript='CLONEID_schema.sql')

# # Specify the clone ID for which we want to find descendants.
cl <- "SNU-668_A9_seed"
# # cl <- "SNU-668_A9_seedT3"

# # Find all descendands of the specified clone ID, excluding any recursive results.
out <- findAllDescendandsOf(ids = cl, recursive = FALSE)

## GenomePerspective
mydb = cloneid::connect2DB()

# ## Do we have Genome sequencing data for any lineage from this cell line?
stmt = paste0("select distinct origin from Perspective where whichPerspective='GenomePerspective' and sampleSource = '",unique(out$cellLine),"'")
rs = suppressWarnings(dbSendQuery(mydb, stmt))
origin=fetch(rs, n=-1)[,"origin"]
origin="SNU-668"
print(paste0("Origin ", origin, " : ", length(origin)>0))
## Download genomic profile for one subpopulation:
# Get the subclones from the origin
tic("\n### GenomePerspective SNU-668")
sps <- getSubclones(cloneID_or_sampleName = origin, whichP = "GenomePerspective")
# print(sps)
# Extract the genomic profiles for each subclone
# p <- sapply(names(sps), function(x) getSubProfiles(cloneID_or_sampleName = as.numeric(extractID(x)), whichP = "GenomePerspective"))
p <- sapply(names(sps), function(x) getSubProfilesX(x))
# Get the clone membership information
clonemembership <- unlist(sapply(names(p), function(x) rep(x, ncol(p[[x]]))))
# Calculate the clone sizes (number of rows in each profile)
clonesizes <- sapply(p,ncol)
# Create a pie chart with the clone sizes
pie(clonesizes)
# Combine the genomic profiles into a single data frame
p <- do.call(cbind, p)
# Print the dimensions of the combined data frame
print(dim(p))
# Print the first few rows of the combined data frame
print(head(p[,1:min(3,ncol(p))]))
toc()

