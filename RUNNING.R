suppressWarnings(suppressMessages(library(cloneid)))
library(tictoc)

cat(paste0("\n", "\n"))

sqlserver <- 'remote'

sqlsetup <- switch(sqlserver,
        docker = setupCLONEID(host='sql2', port='3306', user='xxxxx', password='xxxxx', database='CLONEID', schemaScript='CLONEID_schema.sql'),
        remote = setupCLONEID(host='xxxxxxxxxxxxx.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com', port='3306', user='xxxxx', password='xxxxx', database='CLONEID', schemaScript='CLONEID_schema.sql')
)

cat(paste0("### Sql Info : "))
cat(paste0("\n", sqlserver, "\n", sqlsetup[1], "\n", sqlsetup[2], "\n"))
cat(paste0("###", "\n", "\n"))

# Specify the clone ID for which we want to find descendants.
cl <- "SNU-668_A9_seed"

# Find all descendands of the specified clone ID, excluding any recursive results.
out <- suppressWarnings(suppressMessages(findAllDescendandsOf(ids = cl, recursive = FALSE)))

## GenomePerspective
## Do we have Genome sequencing data for any lineage from this cell line?

stmt = paste0("select distinct origin from Perspective where whichPerspective='GenomePerspective' and sampleSource = '",unique(out$cellLine),"'")
mydb = cloneid::connect2DB()
rs <- suppressWarnings(dbSendQuery(mydb, stmt))
origin=fetch(rs, n=-1)[,"origin"]


## Download genomic profile for one subpopulation:

report <- paste0("### GenomePerspective : ", origin)
cat(paste0("\n", report, "\n"))
#timing
tic(report)

# Get the subclones from the origin
sps <- getSubclones(cloneID_or_sampleName = origin, whichP = "GenomePerspective")

# Extract the genomic profiles for each subclone
p <- sapply(names(sps), function(x) { y<-as.numeric(extractID(x)); cat(paste0("Processing SP", y, "\n")); cloneid::getSubProfiles(cloneID_or_sampleName = y, whichP = "GenomePerspective") })

#timing
toc()
cat(paste0("\n", "\n"))

# Get the clone membership information
clonemembership <- unlist(sapply(names(p), function(x) rep(x, ncol(p[[x]]))))

# Calculate the clone sizes (number of rows in each profile)
clonesizes <- sapply(p,ncol)

# Combine the genomic profiles into a single data frame
p <- do.call(cbind, p)

# Print the dimensions of the combined data frame
cat(paste('dimensions', dim(p)[1], dim(p)[2], "\n"))

# Print the first few rows of the combined data frame
cat(paste0("\n", "head:\n"))
print(head(p[,1:min(3,ncol(p))]))

cat("\nPress [enter] to exit")
invisible(readLines("stdin", n=1))
quit()

