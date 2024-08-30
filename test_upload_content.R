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

# Initialize timing log files
timing_log_section1 <- "~/Downloads/timing_log_section1.txt"
timing_log_section2 <- "~/Downloads/timing_log_section2.txt"
cat("Timing Log for Section 1\n", file = timing_log_section1, append = FALSE)  # Overwrite the file
cat("Timing Log for Section 2\n", file = timing_log_section2, append = FALSE)  # Overwrite the file

#################
### Section 1 ###
#################

# Start timing Section 1
section1_start_time <- Sys.time()

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

# End timing Section 1
section1_end_time <- Sys.time()
section1_total_time <- as.numeric(difftime(section1_end_time, section1_start_time, units = "secs"))
cat(sprintf("Total time for Section 1: %.2f seconds\n", section1_total_time), file = timing_log_section1, append = TRUE)

#################
### Section 2 ###
#################

# Define the cell line and profiles to compare
cell_line <- "SNU-16"
profiles <- c("genomeprofile", "transcriptomeprofile")
base_path <- "~/Downloads/"

for(prof in profiles){
  
  # Start timing for each profile in Section 2
  profile_start_time <- Sys.time()
  
  # File paths for the master and test branch files
  master_branch_file <- paste0(base_path, "1.2.1_TEST9_", cell_line, "_", prof, ".txt")
  test_branch_file <- paste0(base_path, "1.3.1_TEST8_", cell_line, "_", prof, ".txt")
  
  # Load data from the master and test branches
  master_branch <- read.table(master_branch_file)
  test_branch <- read.table(test_branch_file)
  
  # Calculate pairwise distances between columns
  distance_matrix <- abs(outer(1:ncol(master_branch), 1:ncol(test_branch), 
                               Vectorize(function(i, j) sum(master_branch[, i] != test_branch[, j]))))
  
  # Add a tiny number to the distance matrix to avoid log(0)
  tiny_number <- 1e-10
  distance_matrix <- distance_matrix + tiny_number
  
  # Reorder columns to place identical matches on the diagonal
  ii <- apply(distance_matrix, 1, which.min)
  distance_matrix <- distance_matrix[, ii]
  
  ######################
  #### Heatmap Plot ####
  ######################
  
  # Prepare data for heatmap
  heatmap_data <- melt(log10(distance_matrix))
  colnames(heatmap_data) <- c("MasterBranch", "TestBranch", "LogDistance")
  
  # Create heatmap for pairwise distances on a log scale with an engaging color palette
  heatmap_plot <- ggplot(heatmap_data, aes(x=TestBranch, y=MasterBranch, fill=LogDistance)) +
    geom_tile() +
    scale_fill_gradient(low="#56B1F7", high="#132B43") +  # Engaging blue color palette
    labs(title=paste("Log-Scaled Pairwise Distance Heatmap for", cell_line, prof),
         x="Test Branch Columns",
         y="Master Branch Columns") +
    theme_minimal()
  
  # Save the heatmap to a file
  ggsave(paste0(base_path, "log_distance_heatmap_", cell_line, "_", prof, ".pdf"), plot=heatmap_plot)
  
  # Report the number of matches and non-matches
  num_matches <- sum(diag(distance_matrix) == tiny_number)
  num_non_matches <- ncol(master_branch) - num_matches
  
  cat(paste("Cell line:", cell_line, "\n"))
  cat(paste("Profile:", prof, "\n"))
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

## Log-Scaled Pairwise Distance Heatmap
A heatmap of log-scaled pairwise distances is saved as 'log_distance_heatmap_", cell_line, "_", prof, ".pdf'.
")
  
  # Write the report to an R Markdown file
  report_filename <- paste0(prof,"_profile_comparison_report_", cell_line, ".Rmd")
  report_path <- file.path(base_path, report_filename)
  
  writeLines(report_content, con=report_path)
  
  # Render the report to a PDF and save it
  output_pdf <- paste0(prof, "_comparison_report_", cell_line, ".pdf")
  rmarkdown::render(report_path, output_format="pdf_document", output_file=output_pdf)
  
  # Clean up intermediate files
  file.remove(report_path)
  
  # End timing for each profile in Section 2
  profile_end_time <- Sys.time()
  profile_total_time <- as.numeric(difftime(profile_end_time, profile_start_time, units = "secs"))
  cat(sprintf("Total time for profile %s in Section 2: %.2f seconds\n", prof, profile_total_time), file = timing_log_section2, append = TRUE)
}

