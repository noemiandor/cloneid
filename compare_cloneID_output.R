# compare_cloneID_output.R

# Load required libraries
library(tictoc)
library(rmarkdown)

cls <- sort(c("NUGC-4","NCI-N87","HGC-27","KATOIII","SNU-668" ,"MKN-45","SNU-638","SNU-601"))

# Base file paths
base_path <- "~/Downloads/"

for(cell_line in cls){
  
  # File paths
  master_branch_file <- paste0(base_path, "1.2.1_", cell_line, "_genomeprofile.txt")
  test_branch_file <- paste0(base_path, "1.3.1_", cell_line, "_genomeprofile.txt")
  
  # Timing file paths
  master_timing_file <- paste0(base_path, "1.2.1_", cell_line, "_timing_log.txt")
  test_timing_file <- paste0(base_path, "1.3.1_", cell_line, "_timing_log.txt")
  
  # Load data
  master_branch <- read.table(master_branch_file)
  test_branch <- read.table(test_branch_file)
  
  # Load timing data
  master_timing <- read.table(master_timing_file, header = TRUE, sep = "\t")
  test_timing <- read.table(test_timing_file, header = TRUE, sep = "\t")
  
  test_timing <- (sum(test_timing$Subclone.ID)*60)/ncol(test_branch)
  master_timing <- (sum(master_timing$Subclone.ID)*60)/ncol(master_branch)
  
  # Dimensions
  dim_master_branch <- dim(master_branch)
  dim_test_branch <- dim(test_branch)
  
  # Use column names from master_branch to check against test_branch
  reference_columns <- names(master_branch)
  target_columns <- names(test_branch)
  
  # Identify matching and non-matching columns by name
  matching_columns <- sapply(reference_columns, function(col) col %in% target_columns)
  non_matching_columns <- which(!matching_columns)
  num_matching_columns <- sum(matching_columns)
  num_total_columns_master_branch <- length(reference_columns)
  
  # Record timing for comparison
  tic("Comparison Timing")
  
  # Summary statistics for matching columns
  matching_column_names <- reference_columns[matching_columns]
  if (num_matching_columns > 0) {
    summary_master_branch <- data.frame(
      Mean = sapply(master_branch[matching_column_names], mean, na.rm = TRUE),
      Median = sapply(master_branch[matching_column_names], median, na.rm = TRUE),
      Mode = sapply(master_branch[matching_column_names], function(v) {
        uniqv <- unique(v)
        uniqv[which.max(tabulate(match(v, uniqv)))]
      })
    )
    
    summary_test_branch <- data.frame(
      Mean = sapply(test_branch[matching_column_names], mean, na.rm = TRUE),
      Median = sapply(test_branch[matching_column_names], median, na.rm = TRUE),
      Mode = sapply(test_branch[matching_column_names], function(v) {
        uniqv <- unique(v)
        uniqv[which.max(tabulate(match(v, uniqv)))]
      })
    )
    
    # Compare the summary statistics
    comparison <- summary_master_branch == summary_test_branch
    comparison_result <- data.frame(Statistic = rownames(summary_master_branch), comparison)
    
    # Check for any non-matching (false) entries
    has_false <- any(comparison == FALSE)
    if (has_false) {
      false_entries <- which(comparison == FALSE, arr.ind = TRUE)
      discrepancy_details <- apply(false_entries, 1, function(index) {
        row_name <- rownames(summary_master_branch)[index[1]]
        col_name <- colnames(comparison)[index[2]]
        paste0("* **", col_name, "** does not match for **", row_name, "**")
      })
    } else {
      discrepancy_details <- NULL
    }
  } else {
    comparison_result <- NULL
    has_false <- FALSE
    discrepancy_details <- NULL
  }
  
  # Check 5 random columns for identical entries if possible
  set.seed(123)  # Set seed for reproducibility
  random_columns <- if (num_matching_columns > 0) sample(matching_column_names, min(5, num_matching_columns)) else NULL
  
  column_comparisons <- list()
  
  if (!is.null(random_columns)) {
    for (col in random_columns) {
      identical_entries <- all(master_branch[, col] == test_branch[, col])
      differing_rows <- which(master_branch[, col] != test_branch[, col])
      
      comparison_text <- if (identical_entries) {
        paste0("* Column ", which(matching_column_names == col), ": All entries are identical.")
      } else {
        paste0("* Column ", which(matching_column_names == col), ": Entries differ at rows ", paste(differing_rows, collapse = ", "))
      }
      column_comparisons[[col]] <- comparison_text
    }
  }
  
  # Record timing for comparison
  comparison_time <- toc()
  
  # Generate the PDF report
  report_content <- "
# Comparison Report

## Input Files
- master_branch file: `r master_branch_file`
- test_branch file: `r test_branch_file`

## Dimensions
- master_branch dimensions: `r dim_master_branch`
- test_branch dimensions: `r dim_test_branch`

`r if (all(dim_master_branch == dim_test_branch)) 'Both dataframes have the same dimensions.' else 'Dataframes have different dimensions.'`

## Column Names
- Total number of columns in master_branch: `r num_total_columns_master_branch`
- Number of matching column names in test_branch: `r num_matching_columns`

## Non-Matching Columns
`r if (length(non_matching_columns) > 0) {
  paste(paste('* Column', non_matching_columns), collapse = '\n')
} else {
  'All column names in master_branch have a match in test_branch.'
}`

## Summary Statistics Comparison
`r if (is.null(comparison_result)) 'No common columns to compare.' else if (has_false) 'Discrepancies found in the summary statistics.' else 'Both dataframes are consistent; all summary statistics are identical for the matching columns.'`

## Discrepancy Details
`r if (!is.null(discrepancy_details)) paste(discrepancy_details, collapse = '\n') else 'No discrepancies found.'`

## Random Column Checks
`r if (length(column_comparisons) > 0) {
  paste(unlist(column_comparisons), collapse = '\n')
} else {
  'No columns to compare for entry-level differences.'
}`

## Timing

### Comparison Process
- The comparison process took `r comparison_time$toc - comparison_time$tic` seconds.

### Timing Details from Master Branch
- Genome profiling process took `r paste(capture.output(print(master_timing)), collapse = '\n')` seconds per cell on master_branch

### Timing Details from Test Branch
- Genome profiling process took `r paste(capture.output(print(test_timing)), collapse = '\n')` second per cell on test_branch
"
  
  # Create a report file name based on the cell line
  report_filename <- paste0("genome_profile_comparison_report_", cell_line, ".Rmd")
  report_path <- file.path(base_path, report_filename)
  
  # Write report to an R Markdown file
  writeLines(report_content, con = report_path)
  
  # Render the report to a PDF with a name based on the cell line
  output_pdf <- paste0("comparison_report_", cell_line, ".pdf")
  rmarkdown::render(report_path, output_format = "pdf_document", output_file = output_pdf)
  
  # Clean up intermediate files
  file.remove(report_path)
}
