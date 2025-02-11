# -------------------------------------------------------
# match_cells.R
# -------------------------------------------------------
# A script that:
#   1. Reads in a TSV file.
#   2. Reads in an RDS file containing a Seurat object.
#   3. Matches/filters data by cell ID.
#   4. Adds the TSV data as metadata columns to the Seurat object.
#   5. Saves the updated Seurat object.
# -------------------------------------------------------

# Load required library
library(Seurat)

# Set read/write locations
tsv_file   <- "~/Downloads/cell_aa_chg.tsv"
rds_file   <- "~/Downloads/HCT116.harmony.Cellcycle.aggr.rds"
output_rds <- "~/Downloads/updated_seurat_object.rds"

# -- 1. Read the TSV file
cat("Reading TSV file:", tsv_file, "\n")
tsv_data <- read.table(
  "~/Downloads/cell_aa_chg.tsv",
  header = TRUE,
  sep = "\t",
  quote = "",
  fill = TRUE,
  comment.char = "",
  stringsAsFactors = FALSE
)

# -- 2. Read the Seurat object from the RDS file
cat("Reading Seurat object:", rds_file, "\n")
seurat_obj <- readRDS(rds_file)

# -- 3. Match the cells in both (by cell name)
# Make "cell_barcode" the row names and match to the colnames of the seurat object
rownames(tsv_data) <- tsv_data$cell_barcode
tsv_data$cell_barcode <- NULL

common_cells <- intersect(rownames(tsv_data), colnames(seurat_obj))
cat("Number of matching cells:", length(common_cells), "\n")

if (length(common_cells) == 0) {
  stop("No matching cell IDs were found between the TSV and the Seurat object.")
}

tsv_data_matched <- tsv_data[common_cells, , drop = FALSE]
seurat_obj_sub   <- subset(seurat_obj, cells = common_cells)

# Add the TSV columns (including protein_chg) to meta.data
cat("Adding TSV data as metadata to the Seurat object.\n")
new_metadata <- seurat_obj_sub@meta.data
new_metadata <- cbind(new_metadata, tsv_data[common_cells, , drop = FALSE])
seurat_obj_sub@meta.data <- new_metadata

stopifnot(all(rownames(new_metadata) == rownames(tsv_data_matched)))
new_metadata <- cbind(new_metadata, tsv_data_matched)
seurat_obj_sub@meta.data <- new_metadata

cat("Saving updated Seurat object to:", output_rds, "\n")
saveRDS(seurat_obj_sub, file = output_rds)
