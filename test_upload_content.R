# This script has two main sections
# You will need to complete all steps in Section 1 before moving to Section 2
# Section 1 adds new entries to the GenomePerspective and TranscriptomePerspective
# It is intended that you add these entries to one branch, clear the environment, and add for another branch before moving to Section 2
# Branches are identified via their differeing versions of the cloneID package
# Section 2 reads in the entries you just wrote to the two branches, and checks for identical columns across the two datasets
# The column names will not match, as new IDs are generated for the datasets when you upload them

# Set up environment
options(java.parameters = "-Xmx7g")
setwd("~/Repositories/cloneid/")
PREFIX <- "TEST9_"
library(cloneid)
library(liayson)
library(matlab)
library(ggplot2)
data(CloneProfiles)

version <- packageVersion("cloneid")

#################
### Section 1 ###
#################

for(p in names(CloneProfiles)[1:2]){
  dataset_start_time <- Sys.time()
  print(paste("Number of cells in", p, "dataset:", sum(sapply(CloneProfiles[[p]], ncol))))
  total_cells <- sum(sapply(CloneProfiles[[p]], ncol))
  OUT <- paste0("~/Downloads/testViewPerspective", filesep, p)
  dir.create(OUT, recursive = TRUE)
  
  for(name in names(CloneProfiles[[p]])){
    tab <- CloneProfiles[[p]][[name]]
    ii <- grep("Clone_", colnames(tab))
    ii <- union(ii, grep("SP_", colnames(tab)))
    write.table(tab, file=paste0(OUT, filesep, PREFIX, name), sep="\t", quote=FALSE, row.names=FALSE)
  }
  
  name <- paste0(PREFIX, grep("spstats", names(CloneProfiles[[p]]), value=TRUE))
  suffix <- paste0(PREFIX, grep("spstats", names(CloneProfiles[[p]]), invert=TRUE, value=TRUE)[1])
  suffix <- gsub(fileparts(name)$name, "", suffix)
  viewPerspective(spstatsFile=paste0(OUT, filesep, name), whichP=p, suffix=suffix)
}

# Get subclones from the origin
sps <- getSubclones(cloneID_or_sampleName = "TEST9_SNU-16", whichP = "GenomePerspective")

# Extract genomic profiles
p <- sapply(names(sps), function(x) {
  y <- as.numeric(extractID(x))
  print(paste0("Processing SP", y))
  
  # Get subprofiles
  result <- cloneid::getSubProfiles(cloneID_or_sampleName=y, whichP="GenomePerspective")
  return(result)
})

# Combine genomic profiles
clonemembership <- unlist(sapply(names(p), function(x) rep(x, ncol(p[[x]]))))
clonesizes <- sapply(p, ncol)
p <- do.call(cbind, p)

# Write combined genomic profiles
write.table(p, file=paste0("~/Downloads/", version, "_", PREFIX, "SNU-16", "_genomeprofile.txt"), sep="\t", quote=FALSE, row.names=TRUE)

#################
### Section 2 ###
#################

cls <- c("SNU-16")
base_path <- "~/Downloads/"

for(cell_line in cls){
  
  # File paths
  master_branch_file <- paste0(base_path, "1.2.1_TEST9_", cell_line, "_genomeprofile.txt")
  test_branch_file <- paste0(base_path, "1.3.1_TEST8_", cell_line, "_genomeprofile.txt")
  
  # Load data
  master_branch <- read.table(master_branch_file)
  test_branch <- read.table(test_branch_file)
  
  # Calculate pairwise identical matches
  identical_matrix <- outer(1:ncol(master_branch), 1:ncol(test_branch), 
                            Vectorize(function(i, j) all(master_branch[, i] == test_branch[, j])))
  
  # Reorder columns to place the identical matches on the diagonal
  ii <- apply(identical_matrix, 1, which.max)
  identical_matrix <- identical_matrix[, ii]
  
  # Filter to only include identical matches (TRUE)
  scatter_data <- expand.grid(MasterBranch=1:ncol(master_branch), TestBranch=1:ncol(test_branch))
  scatter_data$Identical <- as.vector(identical_matrix)
  scatter_data <- scatter_data[scatter_data$Identical, ]
  
  # Create a scatter plot
  scatter_plot <- ggplot(scatter_data, aes(x=TestBranch, y=MasterBranch)) +
    geom_point(size=3, color="blue") +
    labs(title=paste("Pairwise Identical Columns for", cell_line),
         x="Test Branch Columns",
         y="Master Branch Columns") +
    theme_minimal()
  
  # Save the plot
  ggsave(paste0(base_path, "identical_scatter_plot_", cell_line, ".pdf"), plot=scatter_plot)
  
  # Report the number of matches and non-matches
  num_matches <- sum(diag(identical_matrix))
  num_non_matches <- ncol(master_branch) - num_matches
  
  cat(paste("Cell line:", cell_line, "\n"))
  cat(paste("Number of identical columns:", num_matches, "\n"))
  cat(paste("Number of non-identical columns:", num_non_matches, "\n"))
  
  # Generate the PDF report
  report_content <- paste0("
# Comparison Report

## Input Files
- master_branch file: ", master_branch_file, "
- test_branch file: ", test_branch_file, "

## Column Comparisons
- Number of identical columns: ", num_matches, "
- Number of non-identical columns: ", num_non_matches, "

## Pairwise Identical Scatter Plot
A scatter plot of pairwise identical columns is saved as 'identical_scatter_plot_", cell_line, ".pdf'.
")
  
  # Create a report file name based on the cell line
  report_filename <- paste0("genome_profile_comparison_report_", cell_line, ".Rmd")
  report_path <- file.path(base_path, report_filename)
  
  # Write report to an R Markdown file
  writeLines(report_content, con=report_path)
  
  # Render the report to a PDF with a name based on the cell line
  output_pdf <- paste0("comparison_report_", cell_line, ".pdf")
  rmarkdown::render(report_path, output_format="pdf_document", output_file=output_pdf)
  
  # Clean up intermediate files
  file.remove(report_path)
}
