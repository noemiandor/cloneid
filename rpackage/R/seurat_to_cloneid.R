# seurat_to_cloneid.R


seuratToCloneProfiles <- function(rds_file, 
                                  namesample, 
                                  assay = "RNA",
                                  slot = "data") {
  # 1) Load updated Seurat that now has protein_chg in meta.data
  library(Seurat)
  seurat_obj_sub <- readRDS(rds_file)
  
  # 2) Prepare clone IDs (clusters), name them by cell barcodes
  clone_ids <- seurat_obj_sub@meta.data$seurat_clusters
  names(clone_ids) <- rownames(seurat_obj_sub@meta.data)
  
  # 2a) Table, fraction
  clone_table <- table(clone_ids)
  total_cells <- sum(clone_table)
  clone_fraction <- clone_table / total_cells
  
  # 3) spstats (layer-1 summary)
  spstats <- data.frame(
    Mean.Weighted = as.numeric(clone_fraction),
    row.names     = names(clone_fraction)
  )
  spstats$ID <- rownames(spstats)
  # Reorder columns: "ID" then "Mean.Weighted"
  spstats <- spstats[, c("ID", "Mean.Weighted")]
  
  # 4) Average expression matrix for layer-1 sps.cbs
  expr_mat <- GetAssayData(seurat_obj_sub, assay = assay, slot = slot)
  clone_list <- split(colnames(expr_mat), clone_ids)
  avg_expr <- sapply(clone_list, function(cell_names) {
    rowMeans(expr_mat[, cell_names, drop = FALSE])
  })
  
  df_sps_cbs <- data.frame(
    LOCUS = rownames(avg_expr),
    avg_expr,
    check.names = FALSE
  )
  
  # 5) Rename columns in df_sps_cbs based on fraction
  for (cloneID in row.names(spstats)) {
    fraction_value <- spstats[cloneID, "Mean.Weighted"]
    new_colname   <- paste0(namesample, ".", formatC(fraction_value, format = "f", digits = 7))
    
    if (cloneID %in% colnames(df_sps_cbs)) {
      colnames(df_sps_cbs)[colnames(df_sps_cbs) == cloneID] <- new_colname
    }
  }
  
  # 6) Build layer-2 data frames (cell-level for each clone)
  tp_list <- list()
  tp_list[[ paste0(namesample, ".spstats") ]] <- spstats
  tp_list[[ paste0(namesample, ".sps.cbs") ]] <- df_sps_cbs
  
  for (cloneID in rownames(spstats)) {
    fraction_value <- spstats[cloneID, "Mean.Weighted"]
    layer2_name <- paste0(
      namesample, ".", 
      formatC(fraction_value, format = "f", digits = 7),
      ".sps.cbs"
    )
    
    clone_cells <- names(clone_ids)[clone_ids == cloneID]
    subpop_expr <- expr_mat[, clone_cells, drop = FALSE]
    
    subpop_df <- data.frame(
      LOCUS = rownames(subpop_expr),
      subpop_expr,
      check.names = FALSE
    )
    tp_list[[ layer2_name ]] <- subpop_df
  }
  
  # (B) Build protein-chg incidence by clone
  # Extract the 'protein_chg' column from the Seurat metadata
  protein_chg_vec <- seurat_obj_sub@meta.data$protein_chg
  names(protein_chg_vec) <- rownames(seurat_obj_sub@meta.data)  # cell barcodes
  
  # Identify all unique protein changes except "WT"
  unique_changes <- setdiff(unique(protein_chg_vec), "WT")
  
  # Create a 0-filled matrix: rows = mutations, columns = clones
  incidence_mat <- matrix(
    0,
    nrow = length(unique_changes),
    ncol = length(clone_table),
    dimnames = list(unique_changes, names(clone_table))
  )
  
  # Fill it in: for each clone, see if it contains each mutation
  for (cloneID in rownames(spstats)) {
    # All cells in this clone
    clone_cells <- names(clone_ids)[clone_ids == cloneID]
    # For each mutation, we check if any cell in clone_cells has that mutation
    these_mutations <- protein_chg_vec[clone_cells]
    
    for (m in unique_changes) {
      if (m %in% these_mutations) {
        incidence_mat[m, cloneID] <- 1
      }
    }
  }
  
  # Rename the columns in incidence_mat to incorporate the fraction
  for (cloneID in rownames(spstats)) {
    fraction_value <- spstats[cloneID, "Mean.Weighted"]
    new_colname   <- paste0(namesample, ".", formatC(fraction_value, format = "f", digits = 7))
    colnames(incidence_mat)[colnames(incidence_mat) == cloneID] <- new_colname
  }
  
  # Convert incidence_mat to a data.frame with "LOCUS" as the first column
  protein_chg_by_clone_df <- data.frame(
    LOCUS = rownames(incidence_mat),
    incidence_mat,
    check.names = FALSE
  )
  
  # Store in the same perspective
  tp_list[[ paste0(namesample, ".proteinChg.sps.cbs") ]] <- protein_chg_by_clone_df
  
  # 7) Final "CloneProfiles" structure
  CloneProfiles <- list()
  CloneProfiles$TranscriptomePerspective <- tp_list
  
  # Return the list object
  return(CloneProfiles)
}


## Example usage

# myCloneProfiles <- seuratToCloneProfiles(
#   rds_file   = "~/Downloads/updated_seurat_object.rds",
#   namesample = "HCT116"
# )
# 
# # Inspect what you got
# names(myCloneProfiles$TranscriptomePerspective)

