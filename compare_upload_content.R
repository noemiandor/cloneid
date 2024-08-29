# # Function to read in summary files
# read_summary <- function(file) {
#   content <- readLines(file)
#   summaries <- list()
#   current_dataset <- NULL
#   
#   for (line in content) {
#     if (grepl("^Summary for", line)) {
#       current_dataset <- gsub("Summary for | in .* dataset:", "", line)
#       summaries[[current_dataset]] <- list()
#     } else if (grepl("^Dimensions:", line)) {
#       # Improved parsing of dimensions
#       dims <- unlist(strsplit(gsub("Dimensions: ", "", line), " rows, "))
#       dims <- as.numeric(gsub(" columns", "", dims))
#       summaries[[current_dataset]]$dimensions <- dims
#     } else if (grepl("^Columns:", line)) {
#       columns <- unlist(strsplit(gsub("Columns: ", "", line), ", "))
#       summaries[[current_dataset]]$columns <- columns
#     }
#   }
#   
#   return(summaries)
# }
# 
# # Function to compare summaries
# compare_summaries <- function(summary1, summary2) {
#   comparisons <- list()
#   
#   datasets <- intersect(names(summary1), names(summary2))
#   
#   for (dataset in datasets) {
#     comp <- list()
#     
#     dims1 <- summary1[[dataset]]$dimensions
#     dims2 <- summary2[[dataset]]$dimensions
#     
#     if (!identical(dims1, dims2)) {
#       comp$dimensions <- list(dims1 = dims1, dims2 = dims2)
#     }
#     
#     cols1 <- summary1[[dataset]]$columns
#     cols2 <- summary2[[dataset]]$columns
#     
#     if (!identical(sort(cols1), sort(cols2))) {
#       comp$columns <- list(cols1 = cols1, cols2 = cols2)
#     }
#     
#     if (length(comp) > 0) {
#       comparisons[[dataset]] <- comp
#     }
#   }
#   
#   return(comparisons)
# }
# 
# # Paths to the summary files
# master_summary_file <- "~/Downloads/upload_summary_GenomePerspective_1.2.1_copy.txt"
# test_tommy_summary_file <- "~/Downloads/upload_summary_GenomePerspective_1.3.1.txt"
# 
# # Read the summary files
# master_summary <- read_summary(master_summary_file)
# test_tommy_summary <- read_summary(test_tommy_summary_file)
# 
# # Compare the summaries
# comparison <- compare_summaries(master_summary, test_tommy_summary)
# 
# # Print the comparison results
# if (length(comparison) > 0) {
#   for (dataset in names(comparison)) {
#     cat(sprintf("Differences found in dataset: %s\n", dataset))
#     
#     if ("dimensions" %in% names(comparison[[dataset]])) {
#       cat("  Dimensions differ:\n")
#       dims1 <- comparison[[dataset]]$dimensions$dims1
#       dims2 <- comparison[[dataset]]$dimensions$dims2
#       cat(sprintf("    Master Summary: %d rows, %d columns\n", dims1[1], dims1[2]))
#       cat(sprintf("    Test Tommy Summary: %d rows, %d columns\n", dims2[1], dims2[2]))
#     }
#     
#     if ("columns" %in% names(comparison[[dataset]])) {
#       cat("  Columns differ:\n")
#       cat("    Master Summary: ", paste(comparison[[dataset]]$columns$cols1, collapse=", "), "\n")
#       cat("    Test Tommy Summary: ", paste(comparison[[dataset]]$columns$cols2, collapse=", "), "\n")
#     }
#     
#     cat("\n")
#   }
# } else {
#   cat("No differences found between the summary files.\n")
# }




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
      dims <- unlist(strsplit(gsub("Dimensions: ", "", line), " rows, "))
      dims <- as.numeric(gsub(" columns", "", dims))
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
  
  datasets <- union(names(summary1), names(summary2))
  
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

# Paths to the summary files
master_summary_file <- "~/Downloads/upload_summary_GenomePerspective_1.2.1_copy.txt"
test_tommy_summary_file <- "~/Downloads/upload_summary_GenomePerspective_1.3.1.txt"

# Read the summary files
master_summary <- read_summary(master_summary_file)
test_tommy_summary <- read_summary(test_tommy_summary_file)

# Compare the summaries
comparison <- compare_summaries(master_summary, test_tommy_summary)

# Print the comparison results
if (length(comparison) > 0) {
  for (dataset in names(comparison)) {
    cat(sprintf("Differences found in dataset: %s\n", dataset))
    
    if ("dimensions" %in% names(comparison[[dataset]])) {
      cat("  Dimensions differ:\n")
      dims1 <- comparison[[dataset]]$dimensions$dims1
      dims2 <- comparison[[dataset]]$dimensions$dims2
      cat(sprintf("    Master Summary: %d rows, %d columns\n", dims1[1], dims1[2]))
      cat(sprintf("    Test Tommy Summary: %d rows, %d columns\n", dims2[1], dims2[2]))
    }
    
    if ("columns" %in% names(comparison[[dataset]])) {
      cat("  Columns differ:\n")
      cat("    Master Summary: ", paste(comparison[[dataset]]$columns$cols1, collapse=", "), "\n")
      cat("    Test Tommy Summary: ", paste(comparison[[dataset]]$columns$cols2, collapse=", "), "\n")
    }
    
    cat("\n")
  }
} else {
  cat("No differences found between the summary files.\n")
}




