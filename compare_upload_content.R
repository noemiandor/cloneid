# compare_upload_content.R

# Function to read in summary files
read_summary <- function(file) {
  content <- readLines(file)
  summaries <- list()
  current_dataset <- NULL
  
  for (line in content) {
    if (grepl("^Summary for", line)) {
      current_dataset <- gsub("Summary for | in .* dataset:", "", line)
      summaries[[current_dataset]] <- list()
    } else if (grepl("^Dimensions:", line)) {
      dims <- as.numeric(unlist(strsplit(gsub("Dimensions: | rows, | columns", "", line), ", ")))
      summaries[[current_dataset]]$dimensions <- dims
    } else if (grepl("^Columns:", line)) {
      columns <- unlist(strsplit(gsub("Columns: ", "", line), ", "))
      summaries[[current_dataset]]$columns <- columns
    }
  }
  
  return(summaries)
}

# Function to compare summaries
compare_summaries <- function(summary1, summary2) {
  comparisons <- list()
  
  datasets <- intersect(names(summary1), names(summary2))
  
  for (dataset in datasets) {
    comp <- list()
    
    dims1 <- summary1[[dataset]]$dimensions
    dims2 <- summary2[[dataset]]$dimensions
    
    if (!identical(dims1, dims2)) {
      comp$dimensions <- list(dims1 = dims1, dims2 = dims2)
    }
    
    cols1 <- summary1[[dataset]]$columns
    cols2 <- summary2[[dataset]]$columns
    
    if (!identical(sort(cols1), sort(cols2))) {
      comp$columns <- list(cols1 = cols1, cols2 = cols2)
    }
    
    if (length(comp) > 0) {
      comparisons[[dataset]] <- comp
    }
  }
  
  return(comparisons)
}

# Example usage:

# Paths to the summary files
summary_file1 <- "~/Downloads/upload_summary_<p1>_<version1>.txt"
summary_file2 <- "~/Downloads/upload_summary_<p2>_<version2>.txt"

# Read the summary files
summary1 <- read_summary(summary_file1)
summary2 <- read_summary(summary_file2)

# Compare the summaries
comparison <- compare_summaries(summary1, summary2)

# Print the comparison results
if (length(comparison) > 0) {
  for (dataset in names(comparison)) {
    cat(sprintf("Differences found in dataset: %s\n", dataset))
    
    if ("dimensions" %in% names(comparison[[dataset]])) {
      cat("  Dimensions differ:\n")
      cat(sprintf("    Summary 1: %d rows, %d columns\n", comparison[[dataset]]$dimensions$dims1))
      cat(sprintf("    Summary 2: %d rows, %d columns\n", comparison[[dataset]]$dimensions$dims2))
    }
    
    if ("columns" %in% names(comparison[[dataset]])) {
      cat("  Columns differ:\n")
      cat("    Summary 1: ", paste(comparison[[dataset]]$columns$cols1, collapse=", "), "\n")
      cat("    Summary 2: ", paste(comparison[[dataset]]$columns$cols2, collapse=", "), "\n")
    }
    
    cat("\n")
  }
} else {
  cat("No differences found between the summary files.\n")
}
