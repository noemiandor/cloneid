##origins must be sorted according to timepoint of sample acquisition
# origins=c( "SNU-668_C_A4_seed"   , "SNU-668_P2_A18k_seed", "SNU-668_P0_A11K_seed")
# origins=c("SNU-668_C_A24_seed","SNU-668_C_A4_seed","SNU-668_G1_A4_seed","SNU-668_G1_A10_seed" )
clusterKaryotypes<- function(origins,whichP = "GenomePerspective", depth=1, path2lanscape=NULL, numClusters=NULL){
  source("~/Repositories/ALFA-K/utils/sim_setup_functions.R")
  source("~/Repositories/ALFA-K/utils/ALFA-K.R")
  library(gplots)
  ploidy=2;
  min_obs = 5;
  dt=5
  
  mydb = cloneid::connect2DB()
  X <- list()
  for(biopsy in origins){
    stmt = paste0("select cloneID, size, alias, parent from Perspective where size=1 and whichPerspective='",whichP,"' and origin = '",biopsy,"'")
    rs = suppressWarnings(dbSendQuery(mydb, stmt))
    sps=fetch(rs, n=-1)
    if(depth>1){
      stmt = paste0("select cloneID, size, alias, parent from Perspective where parent=",sps$cloneID)
      rs = suppressWarnings(dbSendQuery(mydb, stmt))
      sps=fetch(rs, n=-1)
    }
    x=sapply(sps$cloneID, function(x) cloneid::getSubProfiles(cloneID_or_sampleName = x, whichP = whichP), simplify = F)
    X[[biopsy]] = do.call(cbind, x)
  }
  
  ##merge across origins: heatmap
  cnts=sapply(X, function(x) getKaryo(t(x),ploidy)$cn, simplify = F)
  sampleID=unlist(sapply(names(cnts), function(x) rep(x, nrow(cnts[[x]]))))
  col=RColorBrewer::brewer.pal(length(unique(sampleID)),"Paired")
  names(col)=unique(sampleID)
  ii=grep("C_",names(col)); ##Control is gray
  col[ii]= gray.colors(length(ii))
  cnts=do.call(rbind, cnts)
  clusters = findBestClustering(cnts, numClusters=numClusters)+1
  tmp=substr(paste(origins,collapse = "__"),1,90)
  pdf(paste0(tmp,".pdf" ))
  ## Plot karyotypes
  hm=heatmap.2(as.matrix(cnts), margins=c(15,15), colRow = clusters[rownames(cnts)], trace='n', Colv = T,dendrogram = "row", RowSideColors = col[sampleID],key.xlab = "copy number",key.title = "",col=matlab::fliplr(rainbow(20))[5:12], hclustfun=function(x) hclust(x, method="ward.D2"),distfun=function(x) dist(x, method="manhattan"))
  legend("topright",legend = names(col),fill=col,cex = 0.5)
  ## Calculate and plot ploidy
  # dev.new(); plot.new()
  ploidy=calcPloidy(cnts)
  boxplot(ploidy~factor(clusters[names(ploidy)], level=unique(clusters)), xlab="cluster", ylab="ploidy",main = "", col=unique(clusters))
  dev.off()
  
  # ##merge across origins: alfak input
  # cnts=sapply(X, function(x) getKaryo(t(x),ploidy)$karyo, simplify = F)
  # allKaryo=unique(unlist(sapply(cnts, rownames)))
  # cn = matrix(0,length(allKaryo),length(origins))
  # colnames(cn)=origins
  # rownames(cn)=allKaryo
  # for(id in origins){
  #   cn[rownames(cnts[[id]]),id]=cnts[[id]]$freq
  # }
  # 
  # ##run ALFAK
  # if(!file.exists(path2lanscape)){
  #   try(detach("package:cloneid", unload=TRUE),silent = T)
  #   colnames(cn)=seq(dt,dt*ncol(cn),by=dt)
  #   x = list(x=cn, pop.fitness=NULL,dt=dt)
  #   opt <- alfak(x,min_obs = min_obs)
  #   ## Validation: recover frequent clones
  #   xfq <- opt$xo[opt$xo$id=="fq",]
  #   ## Validation: leave one out cross validation - use ALFA-K to predict fitness of frequent clones left out of the training data.
  #   df <- do.call(rbind,lapply(1:nrow(xfq),function(i) optim_loo(i,x,xfq)))
  #   df$f_est = xfq$f_est
  #   ## Save ALFA-K
  #   saveRDS(x,paste0(path2lanscape,matlab::filesep,"alfa-k_input.Rds"))
  #   saveRDS(df,paste0(path2lanscape,matlab::filesep,"alfa-k_crossvalidation.Rds"))
  #   saveRDS(opt$fit,paste0(path2lanscape,matlab::filesep,"krig.Rds"))
  #   saveRDS(opt$xo,paste0(path2lanscape,matlab::filesep,"frequent_clones.Rds"))
  #   fscape <- rbind(cbind(opt$fit$knots, opt$fit$c),c(opt$fit$d))
  #   write.table(fscape, path2lanscape, row.names = FALSE,col.names=FALSE,sep=",")
  # }
  
  names(clusters)=sampleID
  return(clusters)
}


findBestClustering<-function(allKaryo, numClusters=NULL){
  library(cluster)  
  hm=heatmap.2(allKaryo, hclustfun=function(x) hclust(x, method="ward.D2"),distfun=function(x) dist(x, method="manhattan"))
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