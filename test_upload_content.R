# This script has two main sections:
# 1. Section 1: Adds new entries to the GenomePerspective and TranscriptomePerspective.
#    - Complete all steps in Section 1 for one branch, clear the environment, and repeat for another branch before moving to Section 2.
#    - Branches are identified via their differing versions of the cloneID package.
# 2. Section 2: Reads in the entries you just wrote to the two branches and checks for identical columns across the two datasets.
#    - The column names will not match, as new IDs are generated for the datasets when you upload them.

# Set up environment
options(java.parameters = "-Xmx7g")
setwd("~/Repositories/cloneid/")
PREFIX <- "TEST9_"  # Prefix for output files
library(cloneid)
library(liayson)
library(matlab)
library(ggplot2)
library(reshape2)
data(CloneProfiles)

version <- packageVersion("cloneid")

#################
### Section 1 ###
#################

# Process each dataset in CloneProfiles
for(p in names(CloneProfiles)[1:2]){
  dataset_start_time <- Sys.time()
  print(paste("Number of cells in", p, "dataset:", sum(sapply(CloneProfiles[[p]], ncol))))
  
  total_cells <- sum(sapply(CloneProfiles[[p]], ncol))
  OUT <- paste0("~/Downloads/testViewPerspective", filesep, p)
  dir.create(OUT, recursive = TRUE)
  
  # Write each table in the dataset to a file
  for(name in names(CloneProfiles[[p]])){
    tab <- CloneProfiles[[p]][[name]]
    
    # Identify and write Clone_ and SP_ columns
    ii <- grep("Clone_", colnames(tab))
    ii <- union(ii, grep("SP_", colnames(tab)))
    write.table(tab, file=paste0(OUT, filesep, PREFIX, name), sep="\t", quote=FALSE, row.names=FALSE)
  }
  
  # Generate and save the view perspective for the dataset
  name <- paste0(PREFIX, grep("spstats", names(CloneProfiles[[p]]), value=TRUE))
  suffix <- paste0(PREFIX, grep("spstats", names(CloneProfiles[[p]]), invert=TRUE, value=TRUE)[1])
  suffix <- gsub(fileparts(name)$name, "", suffix)
  viewPerspective(spstatsFile=paste0(OUT, filesep, name), whichP=p, suffix=suffix)
}

# Get subclones from the origin and extract genomic profiles
sps <- getSubclones(cloneID_or_sampleName = "TEST9_SNU-16", whichP = "GenomePerspective")
p <- sapply(names(sps), function(x) {
  y <- as.numeric(extractID(x))
  print(paste0("Processing SP", y))
  
  # Extract subprofiles
  result <- cloneid::getSubProfiles(cloneID_or_sampleName=y, whichP="GenomePerspective")
  return(result)
})

# Combine genomic profiles into a single data frame
clonemembership <- unlist(sapply(names(p), function(x) rep(x, ncol(p[[x]]))))
clonesizes <- sapply(p, ncol)
p <- do.call(cbind, p)

# Write the combined genomic profiles to a file
write.table(p, file=paste0("~/Downloads/", version, "_", PREFIX, "SNU-16", "_genomeprofile.txt"), sep="\t", quote=FALSE, row.names=TRUE)

#################
### Section 2 ###
#################

# Define the cell lines to compare
cls <- c("SNU-16")
base_path <- "~/Downloads/"

for(cell_line in cls){
  
  # File paths for the master and test branch files
  master_branch_file <- paste0(base_path, "1.2.1_TEST9_", cell_line, "_genomeprofile.txt")
  test_branch_file <- paste0(base_path, "1.3.1_TEST8_", cell_line, "_genomeprofile.txt")
  
  # Load data from the master and test branches
  master_branch <- read.table(master_branch_file)
  test_branch <- read.table(test_branch_file)
  
  # Calculate pairwise distances between columns
  distance_matrix <- abs(outer(1:ncol(master_branch), 1:ncol(test_branch), 
                               Vectorize(function(i, j) sum(master_branch[, i] != test_branch[, j]))))
  
  # Reorder columns to place identical matches on the diagonal
  ii <- apply(distance_matrix, 1, which.min)
  distance_matrix <- distance_matrix[, ii]
  
  ######################
  #### Heatmap Plot ####
  ######################
  
  # Prepare data for heatmap
  heatmap_data <- melt(distance_matrix)
  colnames(heatmap_data) <- c("MasterBranch", "TestBranch", "Distance")
  
  # Create heatmap for pairwise distances with an engaging color palette
  heatmap_plot <- ggplot(heatmap_data, aes(x=TestBranch, y=MasterBranch, fill=Distance)) +
    geom_tile() +
    scale_fill_gradient(low="#56B1F7", high="#132B43") +  # Engaging blue color palette
    labs(title=paste("Pairwise Distance Heatmap for", cell_line),
         x="Test Branch Columns",
         y="Master Branch Columns") +
    theme_minimal()
  
  # Save the heatmap to a file
  ggsave(paste0(base_path, "distance_heatmap_", cell_line, ".pdf"), plot=heatmap_plot)
  
  # Report the number of matches and non-matches
  num_matches <- sum(diag(distance_matrix) == 0)
  num_non_matches <- ncol(master_branch) - num_matches
  
  cat(paste("Cell line:", cell_line, "\n"))
  cat(paste("Number of identical columns:", num_matches, "\n"))
  cat(paste("Number of non-identical columns:", num_non_matches, "\n"))
  
  # Generate the comparison report
  report_content <- paste0("
# Comparison Report

## Input Files
- master_branch file: ", master_branch_file, "
- test_branch file: ", test_branch_file, "

## Column Comparisons
- Number of identical columns: ", num_matches, "
- Number of non-identical columns: ", num_non_matches, "

## Pairwise Distance Heatmap
A heatmap of pairwise distances is saved as 'distance_heatmap_", cell_line, ".pdf'.
")
  
  # Write the report to an R Markdown file
  report_filename <- paste0("genome_profile_comparison_report_", cell_line, ".Rmd")
  report_path <- file.path(base_path, report_filename)
  
  writeLines(report_content, con=report_path)
  
  # Render the report to a PDF and save it
  output_pdf <- paste0("comparison_report_", cell_line, ".pdf")
  rmarkdown::render(report_path, output_format="pdf_document", output_file=output_pdf)
  
  # Clean up intermediate files
  file.remove(report_path)
}
