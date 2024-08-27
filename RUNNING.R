# # Tentative target execution times for download were:
# # - less than 0.0007 minutes per single cell respectively for sparse scRNA-seq data
# # - less than 0.0001 minutes per single cell respectively for scDNA-seq derived copy number data
# # - less than 0.0001 minutes per single cell respectively for low-dimensional Morphology data.

suppressWarnings(suppressMessages(library(cloneid)))
library(tictoc)

setupCLONEID(host='cloneid.cswgogbb5ufg.us-east-1.rds.amazonaws.com', port='3306', user='thomas', password='densitydependence', database='CLONEID', schemaScript='CLONEID_schema.sql')

version <- packageVersion("cloneid")

sqlserver <- 'remote'

sqlsetup <- switch(sqlserver,
                   docker = setupCLONEID(host='sql2', port='3306', user='thomas', password='densitydependence', database='CLONEID', schemaScript='CLONEID_schema.sql'),
                   remote = setupCLONEID(host='cloneid.cswgogbb5ufg.us-east-1.rds.amazonaws.com', port='3306', user='thomas', password='densitydependence', database='CLONEID', schemaScript='CLONEID_schema.sql')
)

# Specify the clone ID for which we want to find descendants.
cls <- sort(c("NUGC-4","NCI-N87","HGC-27","KATOIII","SNU-668" ,"MKN-45","SNU-638","SNU-601"))

for(cl in cls){
  
  # Prepare a file to record timing information for this cell line
  timing_file <- paste0("~/Downloads/", version, "_", cl, "_timing_log.txt")
  cat("Subclone ID\tTime (minutes)\n", file = timing_file) # Header
  
  # Find all descendants of the specified clone ID, excluding any recursive results.
  out <- suppressWarnings(suppressMessages(findAllDescendandsOf(ids = cl, recursive = FALSE)))
  
  ## GenomePerspective
  ## Do we have Genome sequencing data for any lineage from this cell line?
  stmt <- paste0("select distinct origin from Perspective where whichPerspective='GenomePerspective' and sampleSource = '", unique(out$cellLine), "'")
  mydb <- cloneid::connect2DB()
  rs <- suppressWarnings(dbSendQuery(mydb, stmt))
  origin <- fetch(rs, n=-1)[,"origin"]
  
  ## Download genomic profile for one subpopulation:
  report <- paste0("### GenomePerspective : ", origin)
  cat(paste0("\n", report, "\n"))
  
  # Get the subclones from the origin
  sps <- getSubclones(cloneID_or_sampleName = origin, whichP = "GenomePerspective")
  
  # Extract the genomic profiles for each subclone and time it
  p <- sapply(names(sps), function(x) {
    y <- as.numeric(extractID(x))
    cat(paste0("Processing SP", y, "\n"))
    
    # Start timing
    tic(paste0("Processing SP", y))
    
    # Get subprofiles
    result <- cloneid::getSubProfiles(cloneID_or_sampleName = y, whichP = "GenomePerspective")
    
    # Stop timing and record time
    time_taken <- toc(quiet = TRUE)
    time_taken_minutes <- (time_taken$toc - time_taken$tic) / 60
    cat(paste(y, format(time_taken_minutes, digits=6), "\n", sep="\t"), file = timing_file, append = TRUE)
    
    return(result)
  })
  
  cat(paste0("\n", "\n"))
  
  # Get the clone membership information
  clonemembership <- unlist(sapply(names(p), function(x) rep(x, ncol(p[[x]]))))
  
  # Calculate the clone sizes (number of rows in each profile)
  clonesizes <- sapply(p, ncol)
  
  # Combine the genomic profiles into a single data frame
  p <- do.call(cbind, p)
  
  # Write the combined genomic profiles to a text file
  write.table(p, file = paste0("~/Downloads/", version, "_", cl, "_genomeprofile.txt"), sep = "\t", quote = FALSE, row.names = TRUE)
}

# Print the dimensions of the combined data frame
cat(paste('dimensions', dim(p)[1], dim(p)[2], "\n"))

# Print the first few rows of the combined data frame
cat(paste0("\n", "head:\n"))
print(head(p[,1:min(3,ncol(p))]))

cat("\nPress [enter] to exit")
invisible(readLines("stdin", n=1))
quit()






