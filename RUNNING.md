### Module3 Testing
## Test bed 
* Hardware:
  * Model Name: MacBook Air
  * Model Identifier: MacBookAir10,1
  * Model Number: MGNA3LL/A
  * Chip: Apple M1
  * Total Number of Cores: 8
  * Memory: 8 GB
* Software:
    * System Version: macOS 14.5 (23F79)
    * Kernel Version: Darwin 23.5.0
    * Java
      * Oracle 22.0.2 2024-07-16
      * Java(TM) SE Runtime Environment (build 22.0.2+9-70)
      * Java HotSpot(TM) 64-Bit Server VM (build 22.0.2+9-70, mixed mode, sharing)
    * R
      * R version 4.4.1 (2024-06-14)
      * Platform: aarch64-apple-darwin23.4.0
      * Running under: macOS Sonoma 14.5

# Using m3 
  * Recompile the cloneid jar : see README.md
  * Rebuild the R package: see README.md
  
# R script './RUNNING.R'
``` R script
suppressWarnings(suppressMessages(library(cloneid)))
library(tictoc)

sqlserver <- 'remote'

sqlsetup <- switch(sqlserver,
        docker = setupCLONEID(host='sql2', port='3306', user='xxxxx', password='xxxxx', database='CLONEID', schemaScript='CLONEID_schema.sql'),
        remote = setupCLONEID(host='xxxxxxxxxxxxx.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com', port='3306', user='xxxxx', password='xxxxx', database='CLONEID', schemaScript='CLONEID_schema.sql')
)

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
```

# R script Output - using master branch - Time : 4330 seconds
``` text

[1] "select *, 'SNU-668_A9_seed' as Ancestor from Passaging where id IN ('SNU-668_A9_seed', 'SNU-668_A9_seedT1', 'SNU-668_A9_seedT10_VT', 'SNU-668_A9_seedT11', 'SNU-668_A9_seedT12', 'SNU-668_A9_seedT13', 'SNU-668_A9_seedT14', 'SNU-668_A9_seedT2', 'SNU-668_A9_seedT3', 'SNU-668_A9_seedT4', 'SNU-668_A9_seedT5', 'SNU-668_A9_seedT6', 'SNU-668_A9_seedT7')"

### GenomePerspective : SNU-668
Processing SP69293
Processing SP69291
Processing SP69288
Processing SP69285
Processing SP69286
Processing SP69284
Processing SP69289
Processing SP69296
Processing SP69283
Processing SP69290
### GenomePerspective : SNU-668: 4329.487 sec elapsed


dimensions 92 933 

head:
                      SP_0.0225568_ID70161 SP_0.0228502_ID70157
1:840001-103440000                       2                    2
1:103940001-125060000                    4                    4
1:145720001-248900000                    3                    3
2:1-154680000                            3                    3
2:154980001-166060000                    2                    2
2:166380001-241880000                    3                    3
                      SP_0.0222314_ID70150
1:840001-103440000                       2
1:103940001-125060000                    4
1:145720001-248900000                    3
2:1-154680000                            3
2:154980001-166060000                    2
2:166380001-241880000                    3

Press [enter] to exit
```


# R script Output - using m3 branch - Time : 283 seconds
``` text

[1] "select *, 'SNU-668_A9_seed' as Ancestor from Passaging where id IN ('SNU-668_A9_seed', 'SNU-668_A9_seedT1', 'SNU-668_A9_seedT10_VT', 'SNU-668_A9_seedT11', 'SNU-668_A9_seedT12', 'SNU-668_A9_seedT13', 'SNU-668_A9_seedT14', 'SNU-668_A9_seedT2', 'SNU-668_A9_seedT3', 'SNU-668_A9_seedT4', 'SNU-668_A9_seedT5', 'SNU-668_A9_seedT6', 'SNU-668_A9_seedT7')"

### GenomePerspective : SNU-668
Processing SP69293
Processing SP69291
Processing SP69288
Processing SP69285
Processing SP69286
Processing SP69284
Processing SP69289
Processing SP69296
Processing SP69283
Processing SP69290
### GenomePerspective : SNU-668: 282.949 sec elapsed


dimensions 92 933 

head:
                      SP_0.0225568_ID70161 SP_0.0228502_ID70157
1:840001-103440000                       2                    2
1:103940001-125060000                    4                    4
1:145720001-248900000                    3                    3
2:1-154680000                            3                    3
2:154980001-166060000                    2                    2
2:166380001-241880000                    3                    3
                      SP_0.0222314_ID70150
1:840001-103440000                       2
1:103940001-125060000                    4
1:145720001-248900000                    3
2:1-154680000                            3
2:154980001-166060000                    2
2:166380001-241880000                    3

Press [enter] to exit
```
