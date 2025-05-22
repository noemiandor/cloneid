
# ---- Load required libraries -------------------------------------------------

library(Seurat)       # single‑cell object handling and analytics
library(pheatmap)     # heatmap visualisation
library(ggplot2)      # general plotting
library(MOFA2)        # multi‑omics factor analysis (not run but loaded)
library(igraph)       # graph/network operations
library(Matrix)       # sparse‑matrix infrastructure

# ---- User‑defined inputs -----------------------------------------------------

rds_file   = "~/Downloads/updated_seurat_object.rds"  # path to Seurat RDS
namesample = "HCT116"                                
assay       = "RNA"  
slot        = "data" 

# ============================================================================ #
#  PART A — Build TranscriptomePerspective
# ============================================================================ #

# 1) Load Seurat object --------------------------------------------------------
#    The object is expected to already contain a metadata column named
#    `protein_chg`, where each cell is annotated as either "WT" or a specific
#    protein‑change label.
seurat_obj <- readRDS(rds_file)

# 2) Derive clone IDs ----------------------------------------------------------
#    We treat the pre‑computed `seurat_clusters` as clone labels. Because Seurat
#    starts cluster numbering at 0, we coerce them to 1‑based factors so that
#    downstream names are prettier (1, 2, 3 … instead of 0, 1, 2 …).
clone_ids <- seurat_obj@meta.data$seurat_clusters       # integer(0‑based)
clone_ids <- as.factor(as.integer(clone_ids)) # shift +1, keep factor
names(clone_ids) <- rownames(seurat_obj@meta.data)      # names = cell barcodes

# 2a) Basic clone statistics ---------------------------------------------------
clone_table    <- table(clone_ids)            # number of cells per clone
total_cells    <- sum(clone_table)            # grand total
clone_fraction <- clone_table / total_cells   # fraction of total per clone

# 3) Assemble layer‑1 summary data.frame (`spstats`) ---------------------------
spstats <- data.frame(                       # one row per clone
  Mean.Weighted = as.numeric(clone_fraction),
  row.names     = names(clone_fraction)
)
spstats$ID <- rownames(spstats)              # keep the ID as a column
spstats <- spstats[, c("ID", "Mean.Weighted")] # reorder: ID first

# 4) Build layer‑1 average expression matrix (`df_sps_cbs`) -------------------
#    For every clone, compute the average (mean) expression of each gene across
#    its member cells.
expr_mat    <- GetAssayData(seurat_obj, assay = assay, slot = slot)
clone_list  <- split(colnames(expr_mat), clone_ids)           # cells per clone
avg_expr    <- sapply(clone_list, function(cell_names) {
  rowMeans(expr_mat[, cell_names, drop = FALSE])
})

df_sps_cbs <- data.frame(avg_expr, check.names = FALSE)       # genes × clones

# 5) Rename clone columns to include their global fraction ---------------------
#    Columns are changed from e.g. "1" → "HCT116.0.1234567" so that each clone
#    is uniquely identifiable by sample name and its mean abundance.
for (cloneID in row.names(spstats)) {
  fraction_value <- spstats[cloneID, "Mean.Weighted"]
  new_colname    <- paste0(namesample, ".", formatC(fraction_value, format = "f", digits = 7))
  if (cloneID %in% colnames(df_sps_cbs)) {
    colnames(df_sps_cbs)[colnames(df_sps_cbs) == cloneID] <- new_colname
  }
}

# 6) Assemble layer‑2 (per‑clone per‑cell matrices) ---------------------------
#    `tp_list` will collect both the layer‑1 summary objects and, for every
#    clone, a cell×gene matrix of raw expression.

tp_list <- list()
# 6a) Add layer‑1 objects
tp_list[[paste0(namesample, ".spstats")  ]] <- spstats
tp_list[[paste0(namesample, ".sps.cbs") ]] <- df_sps_cbs

# 6b) Add layer‑2 tables: one entry per clone
for (cloneID in rownames(spstats)) {
  fraction_value <- spstats[cloneID, "Mean.Weighted"]
  layer2_name    <- paste0(namesample, ".", formatC(fraction_value, format = "f", digits = 7), ".sps.cbs")
  clone_cells    <- names(clone_ids)[clone_ids == cloneID]
  subpop_expr    <- expr_mat[, clone_cells, drop = FALSE]
  subpop_df      <- data.frame(subpop_expr, check.names = FALSE)
  tp_list[[layer2_name]] <- subpop_df
}

# 7) Attach to master list ------------------------------------------------------
CloneProfiles <- list()
CloneProfiles$TranscriptomePerspective <- tp_list

# ============================================================================ #
#  PART B — Build ProteomePerspective (protein change incidence)
# ============================================================================ #

# 1) Prepare metadata -----------------------------------------------------------
protein_chg_vec <- seurat_obj@meta.data$protein_chg
names(protein_chg_vec) <- rownames(seurat_obj@meta.data)   # name by barcode
unique_changes <- setdiff(unique(protein_chg_vec), "WT")  # exclude wild‑type

# 2) Count cells per (clone × protein change) ----------------------------------
count_mat <- matrix(
  0,
  nrow = length(unique_changes),
  ncol = length(clone_table),
  dimnames = list(unique_changes, names(clone_table))
)
for (cloneID in rownames(spstats)) {
  clone_cells     <- names(clone_ids)[clone_ids == cloneID]
  these_mutations <- protein_chg_vec[clone_cells]
  for (m in unique_changes) {
    count_mat[m, cloneID] <- sum(these_mutations == m)
  }
}

# 3) Convert raw counts → fractions within each clone --------------------------
prop_mat <- sweep(count_mat, 2, as.numeric(clone_table), FUN = "/")

# 4) Rename clone columns (same convention as RNA perspective) -----------------
for (cloneID in rownames(spstats)) {
  frac  <- spstats[cloneID, "Mean.Weighted"]
  newnm <- paste0(namesample, ".", formatC(frac, format = "f", digits = 7))
  colnames(prop_mat)[colnames(prop_mat) == cloneID] <- newnm
}

# 5) Layer‑1 fraction summary ---------------------------------------------------
protein_chg_prop_df <- data.frame(prop_mat, check.names = FALSE)

# 6) Collect ProteomePerspective layers ----------------------------------------
proteome_list <- list()
proteome_list[[paste0(namesample, ".spstats")             ]] <- spstats
proteome_list[[paste0(namesample, ".proteinChg.prop.cbs") ]] <- protein_chg_prop_df

# 7) Add layer‑2 binary incidence matrices (clone‑specific) --------------------
for (cloneID in rownames(spstats)) {
  clone_cells <- names(clone_ids)[clone_ids == cloneID]
  sub_inc_mat <- matrix(
    0,
    nrow = length(unique_changes),
    ncol = length(clone_cells),
    dimnames = list(unique_changes, clone_cells)
  )
  for (cell in clone_cells) {
    mut <- protein_chg_vec[cell]
    if (mut != "WT") sub_inc_mat[mut, cell] <- 1
  }
  sub_inc_df <- data.frame(sub_inc_mat, check.names = FALSE)
  frac       <- spstats[cloneID, "Mean.Weighted"]
  layer2_nm  <- paste0(namesample, ".", formatC(frac, format = "f", digits = 7), ".proteinChg.sps.cbs")
  proteome_list[[layer2_nm]] <- sub_inc_df
}

# 8) Attach to master list ------------------------------------------------------
CloneProfiles$ProteomePerspective <- proteome_list

# ============================================================================ #
#  PART C — Example visualizations
# ============================================================================ #

# 1) Extract commonly reused objects ------------------------------------------

# a) Clone‑level stats
spstats <- CloneProfiles$TranscriptomePerspective[[paste0(namesample, ".spstats")]]

# b) Gene‑level average expression (genes × clones)
avg_df       <- CloneProfiles$TranscriptomePerspective[[paste0(namesample, ".sps.cbs")]]
avg_expr_mat <- as.matrix(avg_df)
colnames(avg_expr_mat) <- colnames(avg_df)

# c) Protein‑change fractions (changes × clones)
prop_df  <- CloneProfiles$ProteomePerspective[[paste0(namesample, ".proteinChg.prop.cbs")]]
prop_mat <- as.matrix(prop_df)

# d) Rebuild full cell×gene expression matrix ---------------------------------
expr_list <- lapply(rownames(spstats), function(cl) {
  fracF <- formatC(spstats[cl, "Mean.Weighted"], format = "f", digits = 7)
  nm    <- paste0(namesample, ".", fracF, ".sps.cbs")
  df    <- CloneProfiles$TranscriptomePerspective[[nm]]
  mat   <- as.matrix(df)
  rownames(mat) <- rownames(df)
  mat
})
expr_mat_full <- do.call(cbind, expr_list)

# e) Map every cell back to its clone -----------------------------------------
clone_ids2 <- unlist(lapply(seq_along(expr_list), function(i) {
  cells <- colnames(expr_list[[i]])
  cl    <- rownames(spstats)[i]
  setNames(rep(cl, length(cells)), cells)
}))

# f) Full cell×protein‑change incidence matrix --------------------------------
prot_list <- lapply(rownames(spstats), function(cl) {
  fracF <- formatC(spstats[cl, "Mean.Weighted"], format = "f", digits = 7)
  nm    <- paste0(namesample, ".", fracF, ".proteinChg.sps.cbs")
  df    <- CloneProfiles$ProteomePerspective[[nm]]
  as.matrix(df)  # keeps rownames
})
prot_mat_full <- do.call(cbind, prot_list)

# g) Derived annotation helpers ------------------------------------------------
mut_flag  <- colSums(prot_mat_full) > 0        # TRUE if cell harbours ≥1 change
anno_all  <- seurat_obj@meta.data[, c("protein_chg", "seurat_clusters")]
colnames(anno_all) <- c("ProteinChange", "Clone")
anno_all$Clone <- factor(as.integer(anno_all$Clone))
anno_all$ProteinChange <- ifelse(anno_all$ProteinChange == "WT", "WT", "Mutated")

cells_to_use <- colnames(expr_mat_full)        # restrict to matrix of interest
anno_cells  <- anno_all[cells_to_use, , drop = FALSE]

# ---- UMAP on cells (RNA expression) ------------------------------------------

# 1) Ensure unique row/column names before feeding into Seurat
if (any(duplicated(rownames(expr_mat_full)))) {
  warning("Duplicated genes found — making them unique.")
  rownames(expr_mat_full) <- make.unique(rownames(expr_mat_full))
}
if (any(duplicated(colnames(expr_mat_full)))) {
  warning("Duplicated cell barcodes found — making them unique.")
  colnames(expr_mat_full) <- make.unique(colnames(expr_mat_full))
}

expr_mat_full <- as(expr_mat_full, "dgCMatrix") # convert dense→sparse

so2 <- CreateSeuratObject(counts = expr_mat_full)
so2 <- NormalizeData(so2)
so2 <- FindVariableFeatures(so2)
so2 <- ScaleData(so2)
so2 <- RunPCA(so2, verbose = FALSE)
so2 <- RunUMAP(so2, dims = 1:20, verbose = FALSE)

umap_df <- as.data.frame(Embeddings(so2, "umap"))
umap_df$Clone         <- clone_ids2[rownames(umap_df)]
umap_df$ProteinChange <- mut_flag[rownames(umap_df)]

# Plot UMAP
ggplot(umap_df, aes(umap_1, umap_2, color = Clone, shape = ProteinChange)) +
  geom_point(alpha = 0.8, size = 1.5) +
  theme_minimal() +
  labs(color = "Clone", shape = "Protein change") +
  ggtitle("UMAP of cells (RNA)")

# ---- Heatmap: expression of top 50 HVG ---------------------------------------
vars     <- apply(expr_mat_full, 1, var)
top50HVG <- names(sort(vars, decreasing = TRUE))[1:50]
mat_hvg  <- expr_mat_full[top50HVG, , drop = FALSE]

pheatmap(
  t(mat_hvg),
  annotation_row = anno_cells,
  show_rownames  = FALSE,
  show_colnames  = TRUE,
  cluster_rows   = FALSE,
  main           = "Cell × gene expression (top 50 HVG)"
)

# ---- Heatmap: incidence of top 50 protein changes ---------------------------
prop_df      <- CloneProfiles$ProteomePerspective[["HCT116.proteinChg.prop.cbs"]]
prop_mat     <- as.matrix(prop_df)
change_score <- apply(prop_mat, 1, max)        # max fraction in any clone
top50_changes <- names(sort(change_score, decreasing = TRUE))[1:50]
prot_mat_full_top50 <- prot_mat_full[top50_changes, , drop = FALSE]

pheatmap(
  t(prot_mat_full_top50),
  annotation_row = anno_cells["Clone"],
  show_rownames  = FALSE,
  show_colnames  = TRUE,
  cluster_cols   = TRUE,
  cluster_rows   = FALSE,
  main           = "Cell × protein change incidence (top 50 changes)"
)

# ---- Clone-level correlation vs. mutation burden -----------------------------

# PCA on clone-average expression
gene_vars     <- apply(avg_expr_mat, 1, var)
avg_expr_filt <- avg_expr_mat[gene_vars > 0, , drop = FALSE]
pca_clones    <- prcomp(t(avg_expr_filt), center = TRUE, scale. = TRUE)

pc1       <- pca_clones$x[, 1]
mut_burden <- colSums(prop_mat)

# Build df_corr with the original clone IDs
df_corr <- data.frame(
  CloneID   = rownames(spstats),  # these are "1","2",… from seurat_clusters
  PC1       = pc1,
  MutBurden = mut_burden,
  stringsAsFactors = FALSE
)

# Scatterplot, coloring/labeling by CloneID
ggplot(df_corr, aes(x = MutBurden, y = PC1, color = CloneID, label = CloneID)) +
  geom_point(size = 3) +
  geom_text(vjust = -0.5, size = 3) +
  theme_minimal() +
  labs(
    x     = "Mutation burden (fraction)",
    y     = "PC1 of avg_expr",
    color = "Clone ID"
  ) +
  ggtitle("Clone PC1 vs. Mutation burden")


# ---- Multi-omics integration with mixOmics::DIABLO ---------------------------

# Reassign rownames of each block to the numeric clone IDs
rownames(X_list$RNA)     <- rownames(spstats)
rownames(X_list$Protein) <- rownames(spstats)

# Now group factor is just those clone IDs
Y <- factor(rownames(spstats))

diablo_model <- block.splsda(
  X      = X_list,
  Y      = Y,
  design = matrix(c(0, 1, 1, 0), nrow = 2),
  ncomp  = 2
)

plotIndiv(
  diablo_model,
  comp    = c(1, 2),
  group   = Y,
  legend  = TRUE,
  title   = "DIABLO: RNA vs Protein-change"
)


# ---- Network graph of clone similarity --------------------------------------

# Build graph and then overwrite vertex names
g <- graph_from_adjacency_matrix(adj, mode = "undirected", weighted = TRUE)
V(g)$size  <- 5
V(g)$color <- rainbow(length(V(g)))

# use the original clone IDs as vertex labels
V(g)$name  <- rownames(spstats)

plot(
  g,
  vertex.label     = V(g)$name,
  vertex.label.cex = 0.8,
  edge.width       = E(g)$weight * 2,
  main             = "Clone similarity network (corr > 0.7)"
)


# Requires prop_mat to be "tidy" (melted)
prop_mat_df <- as.data.frame(as.table(prop_mat))
colnames(prop_mat_df) <- c("ProteinChange", "Clone", "Proportion")
# Use original clone IDs if possible for nicer labels

ggplot(prop_mat_df, aes(x = Clone, y = Proportion, fill = ProteinChange)) +
  geom_bar(stat = "identity", position = "stack") +
  theme_bw() +
  labs(title = "Protein Change Composition within Clones", x = "Clone", y = "Cumulative Proportion") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# For UpSetR on a per-cell basis (from prot_mat_full, which is changes x cells)
library(UpSetR)
# Need binary matrix (1 if change present, 0 otherwise)
# prot_mat_full is already binary. Need to convert to data.frame for UpSetR.
upset_data <- as.data.frame(t(prot_mat_full)) # cells x changes
upset(upset_data, nsets = 10, number.angles = 30, point.size = 3.5, line.size = 2,
      mainbar.y.label = "Cells with Intersection", sets.x.label = "Cells per Change")

# Need to melt expr_mat_full for ggplot
# This can be large, so pick a few genes
genes_of_interest <- c("TNFRSF6B", "MT2A", "SNHG29")
plot_data_list <- list()
for(gene in genes_of_interest) {
  if(gene %in% rownames(expr_mat_full)) {
    df <- data.frame(
      Expression = expr_mat_full[gene,],
      Clone = clone_ids2[colnames(expr_mat_full)] # from your section 1e
    )
    df$Gene <- gene
    plot_data_list[[gene]] <- df
  }
}
plot_df_melted <- do.call(rbind, plot_data_list)

# Ensure necessary libraries are loaded
# install.packages(c("dplyr", "tidytext", "ggpubr"))
library(dplyr)
library(ggplot2)
library(tidytext) # For reorder_within
library(ggpubr)   # For stat_compare_means

# Assuming 'plot_df_melted' is already created and has columns:
# Expression, Clone, Gene

# 1. Prepare data for reordering and get comparisons list
# Calculate median expression for each Clone within each Gene to guide reordering
plot_df_enhanced <- plot_df_melted %>%
  group_by(Gene, Clone) %>%
  mutate(median_expresion_clon_gen = median(Expression, na.rm = TRUE)) %>% # CORRECTED LINE
  ungroup() %>%
  # Create a new factor for the x-axis that is ordered by median expression within each gene
  mutate(Clone_ordenado_por_gen = reorder_within(Clone, median_expresion_clon_gen, Gene)) # CORRECTED USAGE

# Generate a list of pairwise comparisons to perform for each gene
# These comparisons use the original 'Clone' names
unique_clones <- levels(factor(plot_df_enhanced$Clone))

# Only create comparisons if there are 2 or more clones
comparisons_list <- list()
if (length(unique_clones) >= 2) {
  comparisons_list <- combn(as.character(unique_clones), 2, FUN = list)
}

# The rest of the plotting code (step 2 and 3) should remain the same:

# 2. Create the plot
p <- ggplot(plot_df_enhanced, aes(x = Clone_ordenado_por_gen, y = Expression, fill = Clone)) +
  geom_violin(trim = FALSE, scale = "width", alpha = 0.8) +
  geom_boxplot(width = 0.1, fill = "white", outlier.shape = NA, alpha = 0.9) +
  # Apply the reordering to the x-axis scales and labels
  scale_x_reordered() +
  facet_wrap(~Gene, scales = "free") + # "free_y" for y-axis, x-axis is handled by reorder_within
  theme_bw(base_size = 12) +
  labs(
    y = "Expression Level",
    x = "Clone ID (ordered by median expression within each gene)", # Updated x-axis label
    title = "Gene Expression by Clone, Ordered by Median",
    fill = "Clone ID"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.title.x = element_text(margin = margin(t = 10)), # Add some space for x-axis title
    strip.text = element_text(size = 11, face = "bold"),
    strip.background = element_rect(fill = "grey90", color = "grey50"),
    legend.position = "top"
  )

# 3. Add pairwise statistical comparisons if there are comparisons to make
if (length(comparisons_list) > 0) {
  p <- p + stat_compare_means(
    comparisons = comparisons_list,
    method = "wilcox.test",      # Wilcoxon rank-sum test (non-parametric)
    label = "p.signif",         # Show significance levels (e.g., *, **, ***)
    hide.ns = TRUE,             # Hide non-significant comparisons to reduce clutter
    symnum.args = list(         # Define symbols for significance levels
      cutpoints = c(0, 0.001, 0.01, 0.05, 1),
      symbols = c("***", "**", "*", "ns") # "ns" won't be shown due to hide.ns=TRUE
    ),
    bracket.size = 0.3,         # Size of the brackets
    step.increase = 0.08        # Space between stacked brackets
  )
}

# Print the plot
print(p)

# -----------------------------------------------------------------------------
# End of script 
# -----------------------------------------------------------------------------