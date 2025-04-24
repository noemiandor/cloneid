##origins must be sorted according to timepoint of sample acquisition
# origins=c( "SNU-668_C_A4_seed"   , "SNU-668_P2_A18k_seed", "SNU-668_P0_A11K_seed")
# origins=c("SNU-668_C_A24_seed","SNU-668_C_A4_seed","SNU-668_G1_A4_seed","SNU-668_G1_A10_seed" )
clusterKaryotypes <- function(
    origins,
    whichP          = "GenomePerspective",
    depth           = 1,
    path2lanscape   = NULL,
    numClusters     = NULL
){
  source("~/Repositories/ALFA-K/utils/sim_setup_functions.R")
  source("~/Repositories/ALFA-K/utils/ALFA-K.R")
  ploidy  <- 2
  min_obs <- 5
  dt      <- 5
  
  mydb  <- cloneid::connect2DB()
  X     <- list()
  
  # 1) Query subprofiles from DB and store them in X
  for(biopsy in origins){
    stmt <- paste0(
      "SELECT cloneID, size, alias, parent 
       FROM Perspective
       WHERE size=1 AND whichPerspective='", whichP, "' AND origin='", biopsy, "'"
    )
    rs <- suppressWarnings(DBI::dbSendQuery(mydb, stmt))
    sps <- DBI::fetch(rs, n = -1)
    
    # If depth > 1, also pull children of these clones
    if(depth > 1) {
      stmt <- paste0(
        "SELECT cloneID, size, alias, parent 
         FROM Perspective 
         WHERE parent IN (", paste(sps$cloneID, collapse=","), ")"
      )
      rs <- suppressWarnings(DBI::dbSendQuery(mydb, stmt))
      sps <- DBI::fetch(rs, n=-1)
    }
    
    # Get the copy-number (or other) profiles for each clone
    x <- sapply(
      sps$cloneID, 
      function(cid) cloneid::getSubProfiles(cloneID_or_sampleName = cid, whichP = whichP), 
      simplify = FALSE
    )
    X[[biopsy]] <- do.call(cbind, x)
  }
  
  ##############################################################################
  # 2) Merge across origins for karyotyping/clustering
  ##############################################################################
  #   - We get CN calls from getKaryo() 
  #   - We cluster them with findBestClustering()
  
  # cnts is a list of data frames (one per origin) with copy-number calls
  cnts_list  <- sapply(X, function(mat) getKaryo(t(mat), ploidy)$cn, simplify = FALSE)
  
  # 'sampleID' identifies the biopsy/origin for each row in combined data
  sampleID <- unlist(
    sapply(names(cnts_list), function(x) rep(x, nrow(cnts_list[[x]])))
  )
  
  # Combine all rows from all origins
  cnts_combined <- do.call(rbind, cnts_list)
  
  
  # Dendrogram parameters
  hFun <- function(x) stats::hclust(x, method = "complete"); #ward.D2
  dFun <- chrWeightedDist; #function(x) stats::dist(x, method = "manhattan")
  
  # If the user specified a number of clusters, we cluster with that many groups.
  # findBestClustering() presumably returns cluster labels from 0..(numClusters-1);
  # The +1 is presumably to shift them to 1..numClusters range.
  clusters <- findBestClustering(cnts_combined, numClusters = numClusters, hFun=hFun, dFun = dFun) + 1
  
  ##############################################################################
  # 3) Plot heatmap with hierarchical clustering to extract dendrogram 
  ##############################################################################
  tmp <- substr(paste(origins, collapse = "__"), 1, 90)
  pdf(paste0(tmp, ".pdf"))
  
  # Color each sampleID differently (for RowSideColors)
  uniqueIDs <- unique(sampleID)
  colVec    <- rep("NA", length(uniqueIDs))
  names(colVec) <- uniqueIDs
  
  # Example scheme: control is gray, everything else from a Brewer palette
  idxControl <- grep("C_", names(colVec))  # or any other pattern for control
  colVec[idxControl] <- gray.colors(length(idxControl))
  
  # The rest get colored from a palette
  remaining <- setdiff(seq_along(colVec), idxControl)
  if(length(remaining) > 0) {
    colPalette <- brewer.pal(min(length(remaining), 12), "Paired")
    if(length(remaining) > length(colPalette)) {
      # Extend the palette if needed
      colPalette <- colorRampPalette(colPalette)(length(remaining))
    }
    colVec[remaining] <- colPalette[seq_along(remaining)]
  }
  
  # Draw the heatmap
  hm <- heatmap.2(
    x           = as.matrix(cnts_combined),
    margins     = c(15,15),
    colRow      = clusters[rownames(cnts_combined)], 
    trace       = 'none',
    Colv        = TRUE,
    dendrogram  = "row",
    RowSideColors = colVec[sampleID],
    key.xlab    = "copy number",
    key.title   = "",
    col         = matlab::fliplr(rainbow(20))[5:12],
    hclustfun   = hFun,
    distfun     = dFun
  )
  
  legend(
    "topright",
    legend = names(colVec),
    fill   = colVec,
    cex    = 0.5
  )
  
  # Boxplot of ploidy by cluster
  ploidy_vals <- calcPloidy(cnts_combined)
  boxplot(
    ploidy_vals ~ factor(clusters[names(ploidy_vals)], levels = unique(clusters)),
    xlab   = "Cluster",
    ylab   = "Ploidy",
    main   = "",
    col    = unique(clusters)
  )
  
  dev.off()
  
  ##############################################################################
  # 4) Summarize and return
  ##############################################################################
  
  # Combine the results by sample
  # grpstats() presumably aggregates mean/median by sample ID
  # (This was in your original code.)
  cnts_summary <- grpstats(cnts_combined, sampleID, statscols = c("mean","median"))
  
  # Name the cluster vector by sample to keep track
  names(clusters) <- sampleID
  rownames(cnts_combined) = paste0(rownames(cnts_combined),"_",sampleID)
  
  return(list(
    clusters    = clusters,        # numeric cluster label per row in cnts_combined
    cnts        = cnts_summary,    # aggregated means/medians
    CN      = cnts_combined,      # the hierarchical clustering object
    distanceFun = dFun,            # for reference if needed
    origins     = origins          # keep track of which origins we used
  ))
}


findBestClustering<-function(allKaryo, numClusters=NULL, hFun=function(x) hclust(x, method="ward.D2"), dFun = function(x) dist(x, method="manhattan")){
  library(cluster)  
  hm=heatmap.2(allKaryo, hclustfun=hFun,distfun=dFun)
  silhouettecoefs=rep(NA,nrow(allKaryo))
  for(k in 2:(nrow(allKaryo)-1)){
    clusters=cutree(as.hclust(hm$rowDendrogram), k=k)
    sil <- summary(silhouette(clusters, dist(allKaryo)))
    silhouettecoefs[k]= sil$si.summary["Median"]
  }
  k = which.max(silhouettecoefs)
  if(!is.null(numClusters)){
    k=numClusters
  }
  clusters=cutree(as.hclust(hm$rowDendrogram), k=k)
  return(clusters)
}

getKaryo<-function(cn,ploidy){
  ## set copy number of chromosome to copy number of largest segment for that chromosome
  segments= sapply(sapply(strsplit(colnames(cn),":"),"[[",2), function(x) strsplit(x[[1]],"-")[[1]],simplify = F)
  segments= as.data.frame(do.call(rbind,sapply(segments, as.numeric,simplify = F)))
  rownames(segments) = colnames(cn)
  colnames(segments) = c("start","end")
  segments$length=1+segments$end-segments$start
  segments$chr = as.numeric(sapply(strsplit(colnames(cn),":"),"[[",1))
  chrsegments=sapply(unique(segments$chr), function(x) segments[segments$chr==x,,drop=FALSE],simplify = F)
  chrsegments=sapply(chrsegments, function(x) x[which.max(x$length),,drop=F],simplify = F)
  chrsegments = do.call(rbind,chrsegments)
  cn=cn[,rownames(chrsegments)]
  colnames(cn)=chrsegments$chr
  
  ## all other chromosomes have copy number equal to ploidy for all cells
  otherchr = setdiff(1:22,colnames(cn))
  cn_ = matrix(ploidy,nrow(cn),length(otherchr))
  colnames(cn_)=otherchr
  cn = cbind(cn,cn_)
  gplots::heatmap.2(cn,trace='n',symbreaks = F,symkey=F)
  
  ## karyotype frequency across timepoints
  cn=round(cn)
  # cn[,apply(cn==0,2,all)]=1
  karyo=apply(cn,1,paste0,collapse=".");
  names(karyo) = rownames(cn)
  karyo_in= plyr::count(karyo)
  rownames(karyo_in)=karyo_in$x
  return(list(karyo=karyo_in[,'freq',drop=F], cn=cn ))
  
}

calcPloidy<-function(cnts){
  x <- fread("http://hgdownload.cse.ucsc.edu/goldenpath/hg19/database/cytoBand.txt.gz", 
             col.names = c("chrom","chromStart","chromEnd","name","gieStain"))
  chrarms=x[ , .(length = sum(chromEnd - chromStart)),by = .(chrom, arm = substring(name, 1, 1)) ]
  chrwhole=grpstats(as.matrix(chrarms$length),chrarms$chrom, "sum")$sum
  
  ii=paste0('chr',colnames(cnts));
  ploidy=apply(cnts,1, function(x) sum(chrwhole[ii,]*x)/sum(chrwhole[ii,]))
  return(ploidy)
}

create_population_df <- function(mueller_data_summary, label_map = NULL) {
  # mueller_data_summary has columns: passage, clone, freq
  # rename them for ggmuller
  population_df <- mueller_data_summary %>%
    rename(
      Generation = passage,
      Identity   = clone,
      Population = freq
    )
  
  # If you used the hclust approach above, your leaf clones 
  # might need to be mapped to the correct label.
  # For example, if label_map is a named vector mapping negative hclust index 
  # to clone names, you can do a factor conversion here.
  
  # If your leaf labels are already correct, skip this step.
  if (!is.null(label_map)) {
    # e.g. population_df$Identity <- label_map[ as.character(population_df$Identity) ]
    # But typically you’d do something more direct if needed
  }
  
  # ggmuller requires numeric or integer time
  population_df$Generation <- as.numeric(as.character(population_df$Generation))
  
  # ensure order
  population_df <- population_df[order(population_df$Generation, population_df$Identity), ]
  
  return(population_df)
}


convert_hclust_to_edges <- function(CN) {
  # Requires gplots for heatmap.2; optional: 'ape' for other manipulations
  if(!requireNamespace("gplots", quietly = TRUE)) {
    stop("Package 'gplots' is required. Please install it using install.packages('gplots').")
  }
  
  # 1. Build an hclust object from the row dendrogram of a heatmap.2
  hFun <- function(x) stats::hclust(x, method = "ward.D2")
  dFun <- function(x) stats::dist(x, method = "manhattan")
  hm <- gplots::heatmap.2(
    as.matrix(CN),
    hclustfun   = hFun,
    distfun     = dFun,
    trace       = "none",
    dendrogram  = "row"
    # ... other heatmap.2 options if you wish ...
  )
  
  hclust_obj    <- as.hclust(hm$rowDendrogram)
  merge_matrix  <- hclust_obj$merge  # size: n_merges x 2
  heights       <- hclust_obj$height # length n_merges, heights of merges in order
  labels        <- hclust_obj$labels # length n_leaves
  n_leaves      <- length(labels)
  n_merges      <- nrow(merge_matrix)
  
  # -------------------------------------------------------------------------
  # 2. For convenience, define:
  #    - cluster indices 1..n_leaves for the original leaves
  #    - cluster indices (n_leaves+1) .. (n_leaves + n_merges) for merges
  #
  #    getClusterIndex(x): maps hclust's "merge" pointer (pos/neg) to 1-based cluster index
  #      < 0 => leaf index (-x)
  #      > 0 => internal merge index (x + n_leaves)
  # -------------------------------------------------------------------------
  
  getClusterIndex <- function(x) {
    if (x < 0) {
      return(-x)  # negative => leaf index
    } else {
      return(n_leaves + x)  # positive => previously formed internal node
    }
  }
  
  # We'll store:
  #   parent[i] = the cluster index of i's parent, if i is a leaf
  #   (for merges, we won't store parent[] because merges do not appear in the final edges
  #    except for the very last one becoming "NodeN")
  #
  #   repLeaf[c] = for cluster c, which leaf is its "representative"?
  #   allLeaves[[c]] = vector of all leaf indices belonging to cluster c.
  
  parent   <- rep(NA_integer_, n_leaves)           # each leaf's parent (will store an integer index of another leaf or NA)
  repLeaf  <- rep(NA_integer_, n_leaves + n_merges) # representative leaf of each cluster
  allLeaves <- vector("list", n_leaves + n_merges)  # list of leaf sets
  
  # Initialize leaf clusters (1..n_leaves)  
  for (leaf_i in seq_len(n_leaves)) {
    parent[leaf_i]        <- NA                     # no parent yet
    repLeaf[leaf_i]       <- leaf_i                 # the leaf is its own representative
    allLeaves[[leaf_i]]   <- leaf_i                 # cluster c = {leaf_i}
  }
  
  # A helper: cluster "height"
  #   if <= n_leaves => leaf => height=0
  #   else => a merged cluster => hclust_obj$height[row], where row = ci - n_leaves
  getClusterHeight <- function(ci) {
    if (ci <= n_leaves) {
      0
    } else {
      # Merged cluster: ci = n_leaves + i => i-th merge
      i <- ci - n_leaves
      heights[i]
    }
  }
  
  # -------------------------------------------------------------------------
  # 3. Iterate over merges in the order they occurred
  #    left, right each refer to clusters (leaf or previously merged).
  #    Compare distance from new node to each side, pick a "winner" cluster.
  #    The other cluster's leaves become children of the winner's repLeaf.
  # -------------------------------------------------------------------------
  
  for (i in seq_len(n_merges)) {
    left  <- merge_matrix[i, 1]
    right <- merge_matrix[i, 2]
    
    leftCI  <- getClusterIndex(left)
    rightCI <- getClusterIndex(right)
    newCI   <- n_leaves + i  # the new cluster formed by this merge
    
    # Distances from the new node i to each child cluster's repLeaf
    iHeight     <- heights[i]
    leftHeight  <- getClusterHeight(leftCI)
    rightHeight <- getClusterHeight(rightCI)
    
    distLeft  <- iHeight - leftHeight
    distRight <- iHeight - rightHeight
    
    # Choose the side with the *smaller* distance to the new node as "winner"
    # If distLeft < distRight => left is winner => right is loser
    if (distLeft < distRight) {
      winnerCI <- leftCI
      loserCI  <- rightCI
    } else {
      winnerCI <- rightCI
      loserCI  <- leftCI
    }
    
    # Re-assign all leaves in the losing cluster to point to the *winner* cluster's repLeaf
    winnerRep <- repLeaf[winnerCI]
    for (lf in allLeaves[[loserCI]]) {
      # set lf's parent to winnerRep (if lf != winnerRep)
      if (lf != winnerRep) {
        parent[lf] <- winnerRep
      }
    }
    
    # Now unify the sets into the new cluster
    allLeaves[[newCI]] <- c(allLeaves[[winnerCI]], allLeaves[[loserCI]])
    
    # The new cluster's representative is the winner's representative
    repLeaf[newCI] <- winnerRep
  }
  
  # -------------------------------------------------------------------------
  # 4. At the very end, the final merge is cluster index = n_leaves + n_merges
  #    That entire cluster will be the top.  We attach its representative leaf
  #    to a single "root" node, e.g. "NodeN".
  # -------------------------------------------------------------------------
  
  final_cluster_index <- n_leaves + n_merges
  root_label <- paste0("Node", n_merges)
  final_rep  <- repLeaf[final_cluster_index]
  
  # If final_rep is a leaf, we treat "NodeN" as the parent
  # (no intermediate node is introduced in edges_df except the root).
  # So let's store something special to indicate "root" as final_rep's parent.
  # We'll treat it as 0 or NA, then handle it in the output.
  parent_of_final_rep <- parent[final_rep]
  # If final_rep had a parent from an earlier merge, we keep that chain,
  # but the topmost leaf in that chain eventually also gets "NodeN".
  # In other words, final_rep is either:
  #   - a leaf that never got re-parented (rare) => parent[final_rep] = NA
  #   - a leaf that *did* get re-parented => we want to find the top leaf in that chain
  #
  # But typically final_rep is a leaf with some chain behind it. We'll just
  # say final_rep's parent remains as is (if it had one), and then we connect
  # final_rep (or its topmost ancestor) to the root.  But to match the user's
  # request *strictly* (the root is the only internal node), we can simply
  # do: parent[final_rep] = -1  (a marker), then in edges we treat -1 => "NodeN".
  #
  # But if final_rep already had a parent, that means there's a chain. In typical
  # hierarchical merges, we do *want* the top chain. Let’s place root above
  # the final_rep anyway:
  
  parent[final_rep] <- -1  # A sentinel for the root parent
  
  # -------------------------------------------------------------------------
  # 5. Build the edges data frame: for each leaf i,
  #    if parent[i] >= 1 => that parent is another leaf
  #    if parent[i] == -1 => that indicates "NodeN"
  #    if parent[i] is NA => the leaf never got re-parented; also goes to root
  # -------------------------------------------------------------------------
  
  edges_list <- list()
  for (lf in seq_len(n_leaves)) {
    par <- parent[lf]
    
    if (is.na(par)) {
      # This leaf never got a parent => attach to root
      edges_list[[length(edges_list) + 1]] <- data.frame(
        Identity = labels[lf],
        Parent   = root_label,
        stringsAsFactors = FALSE
      )
      
    } else if (par == -1) {
      # Root sentinel
      edges_list[[length(edges_list) + 1]] <- data.frame(
        Identity = labels[lf],
        Parent   = root_label,
        stringsAsFactors = FALSE
      )
      
    } else {
      # Normal parent is another leaf
      edges_list[[length(edges_list) + 1]] <- data.frame(
        Identity = labels[lf],
        Parent   = labels[par],
        stringsAsFactors = FALSE
      )
    }
  }
  
  # Combine into a single data frame
  edges_df <- do.call(rbind, edges_list)
  
  return(edges_df)
}


###############################################################################
##                  Mueller Plot Extension                                    ##
###############################################################################
# We'll create a function that:
# 1) Gathers the cluster assignments + passage times for each lineage.
# 2) Summarizes by passage.
# 3) Plots a stacked area chart (Mueller plot) showing frequency per cluster.
# Updated plotMueller function:
plotMuellerGGMuller <- function(cellLine, out_, pass, colorMapping, showPlot = TRUE, includelegend=F) {
  library(MullerPlot)
  library(dplyr)
  library(ggmuller)   # for get_Muller_df, MullerPlot
  
  if (!cellLine %in% names(out_)) {
    stop("No clustering data found for ", cellLine)
  }
  
  # 1) Extract cluster assignments
  clusterAssignments <- out_[[cellLine]]$clusters
  CN <- out_[[cellLine]]$CN
  
  # 2) Build data frame of (lineage, clone, passage)
  mueller_data <- data.frame(
    lineage = names(clusterAssignments),
    clone   = clusterAssignments,
    passage = pass[names(clusterAssignments), "passage"],
    stringsAsFactors = FALSE
  )
  
  # 3) Create full grid + fill missing combos with 0
  clonesUnion <- union(unique(mueller_data$clone), names(colorMapping))
  allPassages <- sort(unique(mueller_data$passage))
  completeData <- expand.grid(passage = allPassages, clone = clonesUnion, stringsAsFactors = FALSE)
  
  mueller_data_summary <- mueller_data %>%
    group_by(passage, clone) %>%
    summarise(n = n(), .groups = "drop")
  
  mueller_data_summary <- base::merge(completeData, mueller_data_summary,
                                      by = c("passage", "clone"), all.x = TRUE)
  mueller_data_summary$n[is.na(mueller_data_summary$n)] <- 0
  
  # Calculate fraction per passage
  totals <- aggregate(n ~ passage, mueller_data_summary, sum)
  names(totals)[2] <- "total"
  mueller_data_summary <- base::merge(mueller_data_summary, totals, by = "passage")
  mueller_data_summary$freq <- mueller_data_summary$n / mueller_data_summary$total
  
  # Convert to "Population" df for ggmuller (Generation, Identity, Population)
  population_df <- create_population_df(mueller_data_summary)
  
  # Filter out clones that have zero frequency at all timepoints
  valid_ids <- population_df %>%
    group_by(Identity) %>%
    summarise(max_pop = max(Population)) %>%
    filter(max_pop > 0) %>%
    pull(Identity)
  
  population_df <- population_df %>%
    filter(Identity %in% valid_ids)
  
  # Update colorMapping
  colorMapping <- colorMapping[names(colorMapping) %in% valid_ids]
  
  # 4) Create edges_df from hclust object
  edges_df <- convert_hclust_to_edges(CN)  # => columns: Identity, Parent
  
  # 4a) Possibly add zero-pop rows for edges that are missing in population_df
  all_id_in_edges <- unique(c(edges_df$Parent, edges_df$Identity))
  missing_ids <- setdiff(all_id_in_edges, unique(population_df$Identity))
  if (length(missing_ids) > 0) {
    generation_totals <- unique(population_df[, c("Generation", "total")])
    missing_rows <- expand.grid(
      Identity    = missing_ids,
      Generation  = generation_totals$Generation,
      stringsAsFactors = FALSE
    )
    missing_rows <- base::merge(missing_rows, generation_totals, by = "Generation", all.x = TRUE)
    missing_rows$n          = 1
    missing_rows$Population = 0.01
    missing_rows <- missing_rows[, c("Generation", "Identity", "n", "total", "Population")]
    population_df <- rbind(population_df, missing_rows)
    population_df <- population_df[order(population_df$Generation, population_df$Identity), ]
  }
  
  # 7) Build final muller_df
  muller_df <- ggmuller::get_Muller_df(edges_df[,c("Parent","Identity")], population_df)
  
  # 8) Plot
  muller_plot <- ggmuller::Muller_plot(muller_df, xlab="", ylab=cellLine) +
    scale_fill_manual(values = colorMapping, name = "Clone/Identity") +
    scale_color_manual(values = colorMapping, name = "Clone/Identity") +
    theme_minimal()  + theme(plot.margin = unit(c(0, 0.2, 0.05, 0.2), "cm"))
   ggtitle(paste("Muller Plot for", cellLine))
  
  if (!includelegend)  muller_plot <- muller_plot + theme(legend.position = "none")
  
  if (showPlot) print(muller_plot)
  
  return(list(
    edges        = edges_df,
    population   = population_df,
    muller_df    = muller_df,
    plot         = muller_plot
  ))
}


# weighted Manhattan distance for an *entire* matrix
chrWeightedDist <- function(mat) {
  # vector of chromosome weights
  w <- chrwhole[paste0("chr", 1:22), 1]
  mat.w <- sweep(mat, 2, w, `*`)         # weight every column
  dist(mat.w, method = "manhattan") / sum(w)
}
