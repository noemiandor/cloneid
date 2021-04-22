findCloneMarkers<-function(sName, ccState = "G0G1"){
  
  ################
  ## Get clones ##
  clones = getSubclones(sName, whichP="Identity")
  imap = cloneid::identity2perspectiveMap(sName,"TranscriptomePerspective")
  clones = cloneid::getSubclones(sName, "TranscriptomePerspective")
  names(clones) = cloneid::extractID(names(clones))
  clones = clones[names(imap)]
  
  print(paste("Gathering TranscriptomePerspective for",length(clones),"clones..."))
  data = gatherSCprofiles(clones, ccState = ccState, whichP = "TranscriptomePerspective")
  
  ############################
  ## Get CellSurfaceMarkers ##
  mydb = connect2DB()
 
  stmt = paste0("select * from CellSurfaceMarkers_hg19");
  rs = dbSendQuery(mydb, stmt)
  kids = fetch(rs, n=-1)
  genes = intersect(kids[,"hgnc_symbol"], rownames(data$X))
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  
  ##################################
  ## Differential gene expression ##
  TESTTYPE="wilcox"; ##"MAST"
  print(paste("Creating seurat object for",ncol(data$X),"representatives of these clones across",length(genes),"cell surface markers..."))
  seu <- Seurat::CreateSeuratObject(counts = data$X[genes,], min.cells = 3, min.features = 200, project = sName)
  seu <- Seurat::NormalizeData(object = seu, normalization.method = "LogNormalize", scale.factor = 10000)
  seu <- Seurat::ScaleData(object = seu); #, vars.to.regress = scale
  rcells = colnames(seu@assays$RNA@data)
  ucols=getCloneColors(sName); 
  ucols=ucols[as.character(unique(data$clones))];  
   
  allMarkers = list() 
  seu@active.ident=as.factor(data$clones[colnames(seu@assays$RNA@data)])
  for(sp in names(clones)){
    if(sum(data$clones==sp,na.rm = T)<5){next;}
    ma=try(Seurat::FindMarkers(seu, ident.1=sp, logfc.threshold = 0.1,only.pos = F,min.pct = 0.01, test.use=TESTTYPE, latent.vars=c("nFeature_RNA"))); 
    if(class(ma)!="try-error"){
      boxplot(seu@assays$RNA@data[rownames(ma)[1], rcells]~data$clones[rcells],xlab="Clone",ylab=paste(rownames(ma)[1],collapse = ", "),col="cyan",main=paste("Clone",sp,"markers"))
      ma=ma[ma$p_val<=0.05,];
      allMarkers[[sp]] = ma[1:min(round(2000/length(clones)),nrow(ma)),]
    }
  }
  goi = unique(do.call(c, lapply(allMarkers, rownames)))
  
  
  ####################################################
  ## Visualize gene expression vs. clone membership ##
  # seu_=try(.pca_tsne_Seurat(seu,goi, do.fast = TRUE, clustering=F, MINPCT_VAREXPLAINED=90, pcs.compute = 10))
  # seu = Seurat::UpdateSeuratObject(seu)
  seu_=try(.pca_tsne_Seurat(seu,goi, do.fast = TRUE, clustering=T, resolution = 0.57, MINPCT_VAREXPLAINED=90, pcs.compute = 20)); #10
  cm = .confusionMatrix(paste("Cluster",as.numeric(seu_@active.ident)), paste("Clone",as.numeric(seu@active.ident[names(seu_@active.ident)])))
  # Seurat::TSNEPlot(seu_)
  cols = ucols[as.character(data$clones[colnames(seu_@assays$RNA@data)])];
  plot(seu_@reductions$tsne@cell.embeddings, col=cols, pch=20, cex=1.75, main=paste0(sName,": ",ncol(seu_@assays$RNA@data)," cells") );  
  legend("topleft",paste("Clone",unique(data$clones[colnames(seu_@assays$RNA@data)])),fill=unique(cols),cex=1.75,bty = "n")
  # umap embedding
  cnfg = umap::umap.defaults
  # cnfg$n_neighbors = 10
  # cnfg$metric = "pearson"
  # um = umap::umap(t(as.matrix(seu_@assays$RNA@data)), config = cnfg)
  um = umap::umap(seu_@reductions$pca@cell.embeddings, config = cnfg)
  cols = ucols[as.character(data$clones[rownames(um$layout)])];
  plot(um$layout, col=cols, pch=20, cex=1.25, main=paste0(sName,": ",nrow(um$data)," cells") );  
  legend("bottomright",paste("Clone",as.numeric(as.factor(unique(data$clones[rownames(um$layout)])))),fill=unique(cols),cex=1.25,bty = "n")
  
  
  ###################################
  ## Find best marker combination ###
  print(paste("Finding best combination among differencially expressed cell surface markers..."))
  destats=data.frame(row.names = names(clones))
  destats[names(imap), "TranscriptomePerspective"] = names(imap)
  destats[names(imap),"origin"] = sapply(names(imap), function(x) getAttribute(x, "TranscriptomePerspective", attr = "origin"))
  for(cloneID in names(clones)){
    M = allMarkers[[cloneID]]
    M$Direction=rep("+",nrow(M)); M$Direction[M$avg_logFC<0]="-"
    M$Alias=paste0(rownames(M)," (",kids$Gene_synonym[match(rownames(M), kids$hgnc_symbol)],")",M$Direction)
    ##Clones stats
    M_=M; rep=1
    while(nrow(M_)>0 && rep<=3 ){ 
      markers = rownames(M_)[1:min(12,nrow(M_))]
      
      bp = list(te = list(estimate = 0))
      bp =.pickAndChooseBestMarker(cloneID, markers, t(data$X[,rcells]), data$clones[rcells])
      if(length(markers)>1){
        bp2=.pickAndChooseBestMarkerPair(cloneID, markers, t(data$X[, rcells]), data$clones[rcells])
        if(abs(bp2$te$estimate)-abs(bp$te$estimate)>0.02){          bp=bp2        }
      }
      if(length(markers)>2){##Pick 3 instead of 2 markers when benefit is significant:
        bp3=.pickAndChooseBestMarkerTrio(cloneID, markers, t(data$X[, rcells]), data$clones[rcells])
        if(abs(bp3$te$estimate)-abs(bp$te$estimate)>0.02){          bp=bp3        }
      }
      if(length(markers)>3){##Pick 4 instead of 3 markers when benefit is significant:
        bp4=.pickAndChooseBestMarker4(cloneID, markers, t(data$X[, rcells]), data$clones[rcells])
        if(abs(bp4$te$estimate)-abs(bp$te$estimate)>0.02){          bp=bp4        }
      }
      
      ##How well can these markers distingusih this clone from others
      par(mfrow=c(1,1),mai=c(1,1,1,1))
      if(bp$g3!="NULL"){
        plot3D::scatter3D(1+jitter(data$X[bp$g1,rcells]), 1+jitter(data$X[bp$g2,rcells]), 1+jitter(data$X[bp$g3,rcells]),colvar = c(1,2)[1+(data$clones[rcells]==cloneID)],pch=20,cex=1,xlab=bp$g1,ylab=bp$g2,zlab=bp$g3,main=M$avg_logFC[match(c(bp$g1,bp$g2,bp$g3),rownames(M))],log='xyz', phi = 10, theta = 40,col=c("gray",ucols[cloneID]),colkey=list(plot = F))
      }else if (bp$g2!="NULL"){
        plot(1+jitter(data$X[bp$g1,rcells]), 1+jitter(data$X[bp$g2,rcells]),col=c("gray",ucols[cloneID])[1+(data$clones[rcells]==cloneID)],pch=20,cex=1,xlab=bp$g1,ylab=bp$g2,main=M$avg_logFC[match(c(bp$g1,bp$g2),rownames(M))],log='xy')
      }
      legend("topright",c(paste(sName,"clone",cloneID),"other clones"),fill=c(ucols[cloneID],"gray"))
      
      ##Record stats
      destats[cloneID, paste0(c("M1","M2","M3","M4"),"_A",rep)] = c(bp$g1,bp$g2,bp$g3,bp$g4)
      ge=paste(sort(M$Alias[rownames(M) %in% c(bp$g1,bp$g2,bp$g3,bp$g4)]),collapse = ", ")
      destats[cloneID,paste0("cor:P_A",rep)]=bp$te$p.value
      destats[cloneID,paste0("cor:R_A",rep)]=abs(bp$te$estimate)
      destats[cloneID,paste0("Markers_A",rep)]=ge
      M_=M_[!rownames(M_) %in% c(bp$g1,bp$g2,bp$g3,bp$g4),,drop=F]
      rep=rep+1
    }
  }
  
  return(destats)
}

# # Example
# out = destats[,grep("_A1",colnames(destats))]
# out$testType = "cor.test"
# out = cbind(destats[,c("origin", "TranscriptomePerspective")], out)
# colnames(out) = c("origin", "cloneID", "M1","M2","M3","M4", "pValue","effectSize", "profile","testType")
# write.csv(out, file="~/Downloads/AllCLs_Flow.csv", row.names = F)


.pickAndChooseBestMarker<-function(clone,genes,X,clones){
  TE=list(estimate=0); G1<-NA
  for(g1 in genes){
    K=try(kmeans(X[,g1,drop=F],centers = grpstats(X[,g1,drop=F],clones==clone,"mean")$mean))
    if(class(K)=="try-error"){
      next
    }
    te=cor.test(K$cluster,as.numeric(clones==clone))
    if(abs(te$estimate)>abs(TE$estimate)){
      TE=te; G1=g1; C=K
    }
  }
  return(list(te=TE,g1=G1,g2="NULL",g3="NULL",g4="NULL",g5="NULL",cluster=C$cluster))
}




.pickAndChooseBestMarkerPair<-function(clone,genes,X,clones,fixed=c()){
  TE=list(estimate=0); G1<-G2<-C<-NA
  for(g1 in genes){
    if(length(fixed)>0){        g1=fixed[1]      }
    for(g2 in setdiff(genes,g1)){
      if(length(fixed)>1){        g2=fixed[2]      }
      K=try(kmeans(X[,c(g1,g2)],centers = grpstats(X[,c(g1,g2)],clones==clone,"mean")$mean))
      if(class(K)=="try-error"){
        next
      }
      te=cor.test(K$cluster,as.numeric(clones==clone))
      if(abs(te$estimate)>abs(TE$estimate)){
        TE=te; G1=g1; G2=g2; C=K
      }
    }
  }
  return(list(te=TE,g1=G1,g2=G2,g3="NULL",g4="NULL",g5="NULL",cluster=C$cluster))
}


.pickAndChooseBestMarkerTrio<-function(clone,genes,X,clones,fixed=c()){
  TE=list(estimate=0); G1<-G2<-G3<-C<-NA
  for(g1 in genes){
    if(length(fixed)>0){        g1=fixed[1]      }
    for(g2 in setdiff(genes,g1)){
      if(length(fixed)>1){        g2=fixed[2]      }
      for(g3 in setdiff(genes,c(g1,g2))){
        if(length(fixed)>2){        g3=fixed[3]      }
        K=try(kmeans(X[,c(g1,g2,g3)],centers = grpstats(X[,c(g1,g2,g3)],clones==clone,"mean")$mean))
        if(class(K)=="try-error"){
          next
        }
        te=cor.test(K$cluster,as.numeric(clones==clone))
        if(abs(te$estimate)>abs(TE$estimate)){
          TE=te; G1=g1; G2=g2; G3=g3; C=K
        }
      }
    }
  }
  return(list(te=TE,g1=G1,g2=G2,g3=G3,g4="NULL",g5="NULL",cluster=C$cluster))
}



.pickAndChooseBestMarker4<-function(clone,genes,X,clones,fixed=c()){
  TE=list(estimate=0); G1<-G2<-G3<-G4<-C<-NA
  for(g1 in genes){
    if(length(fixed)>0){        g1=fixed[1]      }
    for(g2 in setdiff(genes,g1)){
      if(length(fixed)>1){        g2=fixed[2]      }
      for(g3 in setdiff(genes,c(g1,g2))){
        if(length(fixed)>2){        g3=fixed[3]      }
        for(g4 in setdiff(genes,c(g1,g2,g3))){
          if(length(fixed)>3){        g4=fixed[4]      }
          K=try(kmeans(X[,c(g1,g2,g3,g4)],centers = grpstats(X[,c(g1,g2,g3,g4)],clones==clone,"mean")$mean))
          if(class(K)=="try-error"){
            next
          }
          te=cor.test(K$cluster,as.numeric(clones==clone))
          if(abs(te$estimate)>abs(TE$estimate)){
            TE=te; G1=g1; G2=g2; G3=g3; G4=g4; C=K
          }
        }
      }
    }
  }
  return(list(te=TE,g1=G1,g2=G2,g3=G3, g4=G4,g5="NULL",cluster=C$cluster))
}



.pickAndChooseBestMarker5<-function(clone,genes,X,clones,fixed=c()){
  TE=list(estimate=0); G1<-G2<-G3<-G4<-G5<-C<-NA
  for(g1 in intersect(genes,fixed)){
    if(length(fixed)>0){      g1=fixed[1]    }
    for(g2 in setdiff(genes,g1)){
      if(length(fixed)>1){        g2=fixed[2]      }
      for(g3 in setdiff(genes,c(g1,g2))){
        if(length(fixed)>2){        g3=fixed[3]      }
        for(g4 in setdiff(genes,c(g1,g2,g3))){
          if(length(fixed)>3){        g4=fixed[4]      }
          for(g5 in setdiff(genes,c(g1,g2,g3,g4))){
            if(length(fixed)>4){        g5=fixed[5]      }
            K=try(kmeans(X[,c(g1,g2,g3,g4,g5)],centers = grpstats(X[,c(g1,g2,g3,g4,g5)],clones==clone,"mean")$mean))
            if(class(K)=="try-error"){
              next
            }
            te=cor.test(K$cluster,as.numeric(clones==clone))
            if(abs(te$estimate)>abs(TE$estimate)){
              TE=te; G1=g1; G2=g2; G3=g3; G4=g4; G5=g5; C=K
            }
          }
        }
      }
    }
  }
  return(list(te=TE,g1=G1,g2=G2,g3=G3, g4=G4, g5=G5,cluster=C$cluster))
}


.pca_tsne_Seurat<-function(seu_,goi=NULL, do.fast = TRUE, clustering=F, resolution = 0.4, MINPCT_VAREXPLAINED=90, dim.embed=2, pcs.compute = 40, perplexity=30){
  if(is.null(seu_@assays$RNA@scale.data)){
    print("Scaling data first before performing PCA...")
    seu_ <- Seurat::ScaleData(object = seu_);
  }
  if(is.null(goi)){
    goi = seu_@assays$RNA@var.features
  }
  seu_ <- Seurat::RunPCA(object = seu_, features = goi, do.print = F, npcs = pcs.compute)
  ## Set k explaining >=MINPCT_VAREXPLAINED variance
  sdev=seu_@reductions$pca@stdev; sdev=100*sdev/sum(sdev);    k=1
  while(sum(sdev[1:k])<MINPCT_VAREXPLAINED){
    k=k+1
  }
  print(paste("Using",k,"PCs for tSNE..."))
  ## TSNE & clustering
  seu_ <- Seurat::RunTSNE(object = seu_, dims = 1:k, do.fast = do.fast, dim.embed=dim.embed,  perplexity= perplexity)
  if(clustering){
    print("Finding clusters...")
    seu_ <- Seurat::FindNeighbors(object = seu_, dims = 1:k, k.param = 30, reduction = "pca" )
    seu_ <- Seurat::FindClusters(object = seu_, resolution = resolution)
  }
  return(seu_)
}


.confusionMatrix <- function(cc1, cc2){
  mat = matrix(NA, length(unique(cc1)), length(unique(cc2)));
  rownames(mat) = sort(unique(cc1))
  colnames(mat) = unique(cc2)
  for(x in rownames(mat)){
    for(y in colnames(mat)){
      mat[x,y] = sum(cc1==x & cc2==y)
    }
  }
  gplots::heatmap.2(100*sweep(mat, MARGIN = 2, apply(mat, 2, sum), FUN = "/"), margins = c(16,8), col=, Rowv = NULL, Colv = NULL, key.title = "", key.xlab = "% clone")
  return(mat)
}
