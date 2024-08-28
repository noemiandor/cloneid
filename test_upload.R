# ## Record "genotypic" information into CLONEID
# options(java.parameters = "-Xmx7g")
# setwd("~/Repositories/cloneid/")
# PREFIX="TEST7_"
# ## Note: this includes cell morphology info. Referring to a morphology feature as “genotype” is technically not correct. We will need to come up with a better name
# library(cloneid)
# library(liayson)
# library(matlab)
# data(CloneProfiles)
# 
# setupCLONEID(host='cloneid.cswgogbb5ufg.us-east-1.rds.amazonaws.com', port='3306', user='thomas', password='densitydependence', database='CLONEID', schemaScript='CLONEID_schema.sql')
# 
# version <- packageVersion("cloneid")
# 
# # Initialize log file with version in the filename
# log_file <- paste0("~/Downloads/process_time_log_", version, ".txt")
# cat("Processing Time Log\n", file = log_file, append = FALSE) # Create or overwrite the log file
# 
# start_time <- Sys.time()
# 
# total_cells <- 0
# 
# for(p in names(CloneProfiles)[1:2]){
#   dataset_start_time <- Sys.time()
#   print(paste("Number of cells in",p,"dataset:",sum(sapply(CloneProfiles[[p]],ncol))))
#   total_cells <- total_cells + sum(sapply(CloneProfiles[[p]],ncol))
#   OUT=paste0("~/Downloads/testViewPerspective", filesep, p)
#   dir.create(OUT, recursive = T)
#   for(name in names(CloneProfiles[[p]])){
#     tab=CloneProfiles[[p]][[name]]
#     ii=grep("Clone_", colnames(tab))
#     ii=union(ii, grep("SP_", colnames(tab)) )
#     write.table(tab, file=paste0(OUT, filesep, PREFIX, name), sep="\t", quote=F, row.names = F)
#   }
#   name=paste0(PREFIX, grep("spstats", names(CloneProfiles[[p]]), value=T))
#   suffix=paste0(PREFIX, grep("spstats", names(CloneProfiles[[p]]), invert = T, value=T)[1])
#   suffix=gsub(fileparts(name)$name,"",suffix)
#   viewPerspective(spstatsFile = paste0(OUT, filesep, name), whichP = p, suffix = suffix)
#   
#   dataset_end_time <- Sys.time()
#   # Log the time taken for processing the data in seconds/cell
#   time_per_cell <- as.numeric(difftime(dataset_end_time, dataset_start_time, units = "secs")) / sum(sapply(CloneProfiles[[p]], ncol))
#   cat(sprintf("Cell: %s - Time taken per cell: %.2f seconds (Total cells: %d)\n", name, time_per_cell, sum(sapply(CloneProfiles[[p]], ncol))), file = log_file, append = TRUE)
# }
# 
# end_time <- Sys.time()
# total_time_per_cell <- as.numeric(difftime(end_time, start_time, units = "secs")) / total_cells
# cat(sprintf("Time taken per cell for entire dataset: %.2f seconds\n", total_time_per_cell), file = log_file, append = TRUE)
# 


## Record "genotypic" information into CLONEID
options(java.parameters = "-Xmx7g")
setwd("~/Repositories/cloneid/")
PREFIX="TEST7_"
## Note: this includes cell morphology info. Referring to a morphology feature as “genotype” is technically not correct. We will need to come up with a better name
library(cloneid)
library(liayson)
library(matlab)
data(CloneProfiles)

setupCLONEID(host='cloneid.cswgogbb5ufg.us-east-1.rds.amazonaws.com', port='3306', user='thomas', password='densitydependence', database='CLONEID', schemaScript='CLONEID_schema.sql')

version <- packageVersion("cloneid")

# Initialize log file with version in the filename
log_file <- paste0("~/Downloads/process_time_log_", version, ".txt")
cat("Processing Time Log\n", file = log_file, append = FALSE) # Create or overwrite the log file

start_time <- Sys.time()

total_cells <- 0

for(p in names(CloneProfiles)[1:2]){
  dataset_start_time <- Sys.time()
  print(paste("Number of cells in",p,"dataset:",sum(sapply(CloneProfiles[[p]],ncol))))
  total_cells <- total_cells + sum(sapply(CloneProfiles[[p]],ncol))
  OUT=paste0("~/Downloads/testViewPerspective", filesep, p)
  dir.create(OUT, recursive = T)
  
  # Initialize upload summary file with version and p in the filename
  summary_file <- paste0("~/Downloads/upload_summary_", p, "_", version, ".txt")
  cat("Upload Summary\n", file = summary_file, append = FALSE) # Create or overwrite the summary file
  
  for(name in names(CloneProfiles[[p]])){
    tab=CloneProfiles[[p]][[name]]
    ii=grep("Clone_", colnames(tab))
    ii=union(ii, grep("SP_", colnames(tab)) )
    write.table(tab, file=paste0(OUT, filesep, PREFIX, name), sep="\t", quote=F, row.names = F)
    
    # Add a summary of the contents of 'tab' to the summary file
    cat(sprintf("Summary for %s in %s dataset:\n", name, p), file = summary_file, append = TRUE)
    cat(sprintf("Dimensions: %d rows, %d columns\n", nrow(tab), ncol(tab)), file = summary_file, append = TRUE)
    cat(sprintf("Columns: %s\n\n", paste(colnames(tab), collapse=", ")), file = summary_file, append = TRUE)
  }
  name=paste0(PREFIX, grep("spstats", names(CloneProfiles[[p]]), value=T))
  suffix=paste0(PREFIX, grep("spstats", names(CloneProfiles[[p]]), invert = T, value=T)[1])
  suffix=gsub(fileparts(name)$name,"",suffix)
  viewPerspective(spstatsFile = paste0(OUT, filesep, name), whichP = p, suffix = suffix)
  
  dataset_end_time <- Sys.time()
  # Log the time taken for processing the data in seconds/cell
  time_per_cell <- as.numeric(difftime(dataset_end_time, dataset_start_time, units = "secs")) / sum(sapply(CloneProfiles[[p]], ncol))
  cat(sprintf("Cell: %s - Time taken per cell: %.2f seconds (Total cells: %d)\n", name, time_per_cell, sum(sapply(CloneProfiles[[p]], ncol))), file = log_file, append = TRUE)
}

end_time <- Sys.time()
total_time_per_cell <- as.numeric(difftime(end_time, start_time, units = "secs")) / total_cells
cat(sprintf("Time taken per cell for entire dataset: %.2f seconds\n", total_time_per_cell), file = log_file, append = TRUE)
