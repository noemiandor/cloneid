mergePerspectives<-function(perspectives, specimens, simM="euclidean",t=4){
  ##merges either 2 different perspectives on the same specimen OR
  ##the same perspective on 2 or more different specimens
  
  #@TODO: check in database if merge involving these specimens already happened before attempting a new merge
  if(length(perspectives)==1 && length(specimens)>=2){
    out=.onePerspectiveOnManySpecimens(perspective=perspectives[1], sampleNames=specimens, simM=simM, t=t)
  }else if(length(perspectives)==2 && (length(specimens)==1 || length(specimens)==2)){
    if(length(specimens)==1){
      specimens=rep(specimens,2)
    }
    out=.twoPerspectivesOn1Or2Specimens(perspective1=perspectives[1], perspective2=perspectives[2], sampleNames=specimens, simM=simM, t=t)
  }else{
    print("Invalid input: merging either 2 different perspectives on the same specimen OR the same perspective on 2 or more different specimens")
    return()
  }
  return(out)
}

.onePerspectiveOnManySpecimens<-function(perspective="GenomePerspective", sampleNames, simM="hyper", t=4){
  ##Get xy coordinates, mutated loci & count clones
  coord=matrix(NA,length(sampleNames),2); 
  rownames(coord)=sampleNames; colnames(coord)=c("x","y")
  allMut=c(); allClones=c()
  patientName=strsplit(sampleNames[1],"*")[[1]]
  for(s in sampleNames){
    clones=getSubclones(s,whichP=perspective)
    coord[s,]=clones[[1]]$getCoordinates(); 
    for(clone in unlist(clones)){
      allClones=c(allClones,paste(s,clone$toString()))
      allMut=c(allMut,clone$getProfile()$getLoci())
    }
    patientName=LCS(patientName,strsplit(s,"*")[[1]])$LCS
  }
  coord=as.data.frame(coord)
  allMut=unique(allMut)
  
  
  ##Gather allP: rows:=SPs, cols:=SNVs
  allP=matrix(0,length(allClones),length(allMut)); rownames(allP)=allClones; colnames(allP)=allMut
  for(s in sampleNames){
    p=getSubProfiles(s,perspective) 
    allP[paste(s, colnames(p)),rownames(p)]=t(p)
  }
  # allP=allP[,apply(allP!=0,2,sum,na.rm=T)>1]
  
  ###################################
  ####Hierarchical cluster params ###  
  HFUN="ward.D2"
  ##Set distance function
  DFUN=function(x) as.dist(get(simM)(t(x))<t)
  if(simM=="spearman" || simM=="pearson"){
    DFUN=function(x) -cor(t(jitter(x)),method = simM)
  }else if(simM=="euclidean" || simM=="binary"){
    DFUN=function(x) dist(x,method=simM)
  }
  

  ##########################################
  ####Group into k clusters using simM>=t ##
  sNames=sapply(sapply(rownames(allP),strsplit," "),"[[",1)
  col = brewer.pal(length(unique(sNames)),"Paired");   names(col) = unique(sNames)
  o=heatmap.2(t(allP), colCol = col[sNames], cexRow=0.75,distfun=function(x) DFUN(x),col='topo.colors',hclustfun = function(x) hclust(x,method=HFUN),margins = c(11,5))
  allP=allP[o$colInd,]
  Z = hclust(DFUN(allP), method = HFUN)
  TC = cutree(Z, h=t)
  k=length(unique(TC))
  ##Fill k x nRegions matrix with SPs
  sp2clone=matrix(NA,k,nrow(coord)); colnames(sp2clone)=rownames(coord)
  for(c in unique(TC)){
    ii=rownames(allP)[TC==c]
    bpc=plyr::count(sapply(strsplit(ii," "),"[[",1)); ##Biopsies per cluster
    if(any(bpc$freq>1)){
      warning(paste("Multiple clones from same biopsy in same cluster. Increase minimum similarity threshold t (currently at t=",t,")"),immediate. = T)
      print(bpc)
      return(NULL)
    }
    sNames=sapply(sapply(ii,strsplit," "),"[[",1)
    spNames=sapply(sapply(ii,strsplit," "),"[[",2)
    sp2clone[c,match(sNames,colnames(sp2clone))]=spNames
  }
  out=.calculateConsensusProfile(sp2clone,allMut,perspective = perspective)
  
  
  ###################################
  ####Calculate consensus genome ####
  out=.calculateConsensusProfile(sp2clone,allMut,perspective = perspective)
  out$sp2clone_sim=o$colDendrogram
  
  ########################################
  ####Calculate consensus coordinates ####
  sNames = setdiff(colnames(out$sp2clone), "Identity")
  isthere = lapply(1:nrow(out$sp2clone), function(i) out$sp2clone[i,sNames] )
  out$coord = sapply(isthere, function(x) {
    i = !is.na(x);
    o = apply(coord[names(x)[i],]*getSPsize(x[i]),2,sum)
    return( o / sum(getSPsize(x[i])) )
  })
  colnames(out$coord) = out$sp2clone[,"Identity"]
  
  ##Save output
  patientName=paste(patientName,collapse = "")
  outF=paste(getwd(),filesep,patientName,".identity.sps",sep="")
  outF2=paste(getwd(),filesep,patientName,".identity.source",sep="")
  write.table(cbind(out$consdat,rownames(out$consdat)),col.names=c(colnames(out$consdat),"LOCUS"),sep="\t",quote=F,file=outF,row.names = F) ##Save as *sps.cbs format
  write.table(out$sp2clone,col.names=c(rep(perspective,ncol(out$sp2clone)-1),"Identity"),sep="\t",quote=F,file=outF2,row.names = F) ##Save as identity source perspectives
  
  ##Upload consensus perspective to DB as identity
  p<-.jnew("core.Identity",.jnew("java.io.File", outF),"CN_Estimate",.jnew("java.io.File", outF2)) 
  print(p)
  .jcall(p,returnSig ="V",method = "save2DB")
  ##Set coordinates
  sps = getSubclones(patientName, whichP = "Identity")
  sps = sps[sort(names(sps), index.return=T)$ix]
  out$coord = out$coord[,sort(colnames(out$coord), index.return=T)$ix]
  colnames(out$coord) <- names(sps); ## @TODO: check validity 
  for(i in names(sps)){
    sps[[i]]$setCoordinates(as.double(round(out$coord["x",i],2)),as.double(round(out$coord["y",i],2)))
  }
  return(out)
  
}

.twoPerspectivesOn1Or2Specimens<-function(perspective1="GenomePerspective", perspective2="TranscriptomePerspective", sampleNames, simM="euclidean", t=4){
  # make sure perspective 1 is always genome while 2 is always transcriptome
  perspectives=sort(c(perspective1,perspective2))
  perspective1=perspectives[1]; perspective2=perspectives[2];
  
  ###################################
  #####Compare subclone's profiles###
  s1=list();   s2=list(); 
  s2[[perspective2]]=.getProfiles(sampleNames[2],perspective2)
  s1[[perspective1]]=.getProfiles(sampleNames[1],perspective1)
  rows=intersect(rownames(s1[[1]]),rownames(s2[[1]]))
  ##When s1 and s2 don't share a common profile:
  if( length(rows)<min(nrow(s1[[1]]),nrow(s2[[1]])) ){
    s=list(); s[[names(s1)]]=s1[[1]]; s[[names(s2)]]=s2[[1]];
    iMost=which.max(sapply(s,nrow)); iFewest=which.min(sapply(s,nrow))
    ##Segments for which both perspectives have available data
    dm=s[[iFewest]]
    cols=c(grep("^Clone",colnames(s[[iFewest]]),value = T),grep("^SP",colnames(s[[iFewest]]),value = T))
    iK=rownames(dm)[apply(!is.na(dm[,cols,drop=F]),1,sum)>min(1,length(cols)-1)]; 
    s[[iFewest]]=dm[iK,,drop=F]
    ##Assign big segment to small one
    dm=s[[iMost]]
    cols=c(grep("^Clone",colnames(s[[iMost]]),value = T),grep("^SP",colnames(s[[iMost]]),value = T),"bulk")
    dm= assignQuantityToMutation(dm, s[[iFewest]], quantityColumnLabel = "bulk") 
    ##Length-weighted mean CN within big segments
    ii=rownames(dm)[!is.na(dm[,"quantityID"])]
    rowN=rownames(s[[iFewest]])[dm[ii,"quantityID"]]
    tmp=grpstats(dm[ii,cols,drop=F]*dm[ii,"seglength"],rowN,"sum")$sum
    tmp=sweep(tmp,1,FUN="/",grpstats(dm[ii,"seglength",drop=F],rowN,"sum")$sum)

    s[[iMost]]=tmp
    s1=s[1]; s2=s[2]
  }else{
    s2[[perspective2]]=s2[[perspective2]][rows,,drop=F]
    s1[[perspective1]]=s1[[perspective1]][rows,,drop=F]
  }
  allMut=union(rownames(s1[[1]]),rownames(s2[[1]]))
  
  out1=.mergePair(s1, s2, sampleNames=sampleNames, simM=simM, t=t);
  if(isempty(out1$sp2clone)){
    warning(paste(perspective1,"and",perspective2,"are not in agreement for any clones detecetd in ",paste(unique(sampleNames),collapse = ",")))
    return(out1)
  }
  out=.calculateConsensusProfile(out1$sp2clone,allMut,sampleNames,perspective=NULL)
  out$sp2clone_sim=out1$sp2clone_sim
  # out$sim=out1$sim
  out$usedOrder=perspectives
  
  ##Save output
  patientName=paste(unique(sampleNames),collapse = "")
  outF=paste(getwd(),filesep,patientName,".identity.sps.cbs",sep="")
  outF2=paste(getwd(),filesep,patientName,".identity.source",sep="")
  write.table(cbind(out$consdat,rownames(out$consdat)),col.names=c(colnames(out$consdat),"LOCUS"),sep="\t",quote=F,file=outF,row.names = F) ##Save as *sps.cbs format
  write.table(out$sp2clone,sep="\t",quote=F,file=outF2,row.names = F) ##Save as identity source perspectives
  
  ##@TODO: Save consensus perspective to DB as identity
  p<-.jnew("core.Identity",.jnew("java.io.File", outF),"CN_Estimate",.jnew("java.io.File", outF2)) 
  print(p)
  .jcall(p,returnSig ="V",method = "save2DB")
  return(out)
}

.mergePair<-function(theone, theother,sampleNames, simM="euclidean", t=4){
  ##Matches clones from two distinct clonal compositions to each other. 
  ##For example, RNA-derived clones to DNA-derived subpopulations based on the distance between their copy number profiles or
  ##DNA-derived subpopulations from two specimens based on the distance between their point mutation profiles.
  ##theone - subpopulation profiles obtained from one perspective (e.g. single-cell RNA-seq data) or specimen
  ##theother - subpopulation profiles obtained from other perspective (e.g. bulk DNA-sequencing data) or specimen
  one=theone[[1]]
  two=theother[[1]]
  
  
  #   colnames(two)=sapply(strsplit(colnames(two),"_ID"),"[[",1)
  #   colnames(one)=sapply(strsplit(colnames(one),"_ID"),"[[",1)
  buspNames=c(unlist(sapply(c("SP_","Clone_"),grep,colnames(two),value=T))); #,"bulk"
  scspNames=c(unlist(sapply(c("SP_","Clone_"),grep,colnames(one),value=T))); #,"bulk"
  allNames=c(buspNames,scspNames)
  ii=intersect(rownames(one),rownames(two))
  one=one[ii,scspNames,drop=F]; two=two[ii,buspNames,drop=F]
  
  ############################################################################
  ####Calculate pairwise similarity between every clone-subpopulation pair####
  onetwo=t(cbind(one,two)); #round(
  col=rep(.getPerspectiveColor(names(theone)),ncol(one)); col=c(col,rep(.getPerspectiveColor(names(theother)),ncol(two)))
  d=as.matrix(distances::distances(onetwo,weights = parseLOCUS(ii)[,"seglength"]/1E6));
  rownames(d)<-colnames(d)<-rownames(onetwo)
  # d=as.matrix(dist(onetwo));        
  d[T]=d[T]+sample(10000,length(d))/1E9; ##Add noise to avoid cluster-error for perfect match
  Z = hclust(as.dist(d), method = "ward.D2")
  d=d[colnames(one),colnames(two),drop=F]
  hm=heatmap.2(onetwo[Z$labels, ], Rowv = as.dendrogram(Z),
               distfun = function(x) dist(x, method = simM),symm = F,col=fliplr(brewer.pal(11,"RdBu")),
               hclustfun = function(x) hclust(x,method ="ward.D2"), colRow = col[Z$labels], margins = c(10,10),trace="n",na.color="black")
  TC=cutree(as.hclust(hm$rowDendrogram),h=0.001); #k=min(ncol(one),ncol(two))
  ##Find all binary subtrees: members belong to same cluster!
  singletons=plyr::count(TC); singletons=singletons$x[singletons$freq==1]
  TC[TC %in% singletons]=0;     TC=.rank2(TC)
  subtrees <- subtrees(as.phylo(as.hclust(hm$rowDendrogram)))
  subtrees=sapply(subtrees,function(x) x$tip.label)
  for( bintree in subtrees[sapply(subtrees,length)==2]){
    if(all(TC[names(TC) %in% bintree]==0)){
      TC[names(TC) %in% bintree]=max(TC)+1
    }
  }
  TC[TC==0] = (max(TC)+1) : (max(TC) + sum(TC==0))
  

  fr=plyr::count(TC);   fr[,names(theone)]=NA; fr[,names(theother)]=NA
  confirmed=data.frame(row.names = c(names(theone),names(theother))); 
  for(sp in unique(TC)){
    x=names(TC)[TC==sp]
    i1=sapply(x, function(y) y %in% colnames(one))
    i2=sapply(x, function(y) y %in% colnames(two))
    sz=getSPsize(x)
    fr[sp,names(theone)]=sum(sz[i1])
    fr[sp,names(theother)]=sum(sz[i2])
    if(fr[sp,names(theone)]>0 & fr[sp,names(theother)]>0){
      d_=d[names(which(i1)),names(which(i2)),drop=F]
      c_=which(d_ == min(d_), arr.ind=TRUE)
      sz_1=getSPsize(colnames(d_)[c_[,"col"]])
      sz_2=getSPsize(rownames(c_))
      idx= which(sz_1==max(sz_1)); if(length(idx)>1) { idx= idx[ which.max(sz_2[idx]) ] }
      confirmed[names(theone),ncol(confirmed)+1]=rownames(d_)[c_[idx,"row"]]; 
      confirmed[names(theother),ncol(confirmed)]=colnames(d_)[c_[idx,"col"]]; 
    }
  }
  
  ##Replot heatmap to show cluster membership
  colI=grey.colors(max(TC))
  col=c(getCloneColors(sampleNames[1], whichP = names(theone)), getCloneColors(sampleNames[2], whichP = names(theother))); 
  x=sapply(rownames(onetwo),  function(x) strsplit(x,"_ID")[[1]][2])
  col=col[x]
  x_=sapply(as.character(as.matrix(confirmed)),  function(x) strsplit(x,"_ID")[[1]][2])
  col[!names(col) %in% x_]="#E6E6E6"
  heatmap.2(onetwo,RowSideColors = colI[TC], Rowv = hm$rowDendrogram, Colv = hm$colDendrogram,symm=F,col=hm$col,margins = c(13,15), colRow = col,trace="n",na.color="black")
  
  
  out=list(sp2clone=t(confirmed), sp2clone_sim=fr)
  return(out)
}


.calculateConsensusProfile<-function(sp2clone,allMut,sampleNames=NULL,perspective=NULL){
  ###################################
  ####Calculate consensus genome ####
  ##@TODO: the specifics of building the consensus should depend on the perspective
  sp2clone=cbind(sp2clone,matrix(NA,nrow(sp2clone),1)); 
  colnames(sp2clone)[ncol(sp2clone)]="Identity"
  
  consdat=matrix(0,length(allMut),1+nrow(sp2clone)); 
  rownames(consdat)=allMut
  
  for(i in 1:nrow(sp2clone)){
    ##Consensus SP size: @TODO --> unexpected behaviour when two identities have exact same size <=> only one mapped to perspective 
    sI=which(!is.na(sp2clone[i,1:(ncol(sp2clone)-1)]))
    x=sum(as.numeric(sapply(sapply(sp2clone[i,sI],strsplit,"_"),"[[",2)))
    sp2clone[i,"Identity"]=x
    ##Consensus profile:
    for(j in sI){
      sp=sp2clone[i,j]
      id=strsplit(sp,"ID")[[1]][2]
      if(is.null(perspective)){
        p=.getProfiles(sampleNames[j],colnames(sp2clone)[j]); ##constant region: column label has to denote perspective of each SP in corresponding column
        ##Needed when not all perspectives share the exact same profile:
        p= assignQuantityToMutation(p[,c(sp,"chr","startpos","endpos")], p, quantityColumnLabel = sp) 
      }else{
        p=.getProfiles(as.numeric(id),perspective); ##regional variability: all SPs have same perspective
        colnames(p)[colnames(p) == id] = sp
      }
      rows=intersect(rownames(p),rownames(consdat))
      consdat[rows,i]=consdat[rows,i]+p[rows,sp]
    }
    consdat[,i]=consdat[,i]/length(sI)
  }
  iSize=as.numeric(sp2clone[,"Identity"])
  # iSize=round(iSize)/sum(iSize)),4)
  # ##@TODO: this should not be necessary - identities should not be retrieved by their size
  # iSize=iSize+(sample(1E5,length(iSize))-5E4)/1E7;##Slight jitter of identity size to avoid identical sizes
  # warning("Random noise added to clone size to avoid duplicate sizes amongst coexisting Identities")
  sp2clone[,"Identity"]=paste("Clone_",iSize,sep="")
  colnames(consdat)=c(sp2clone[,"Identity"],"CN_Estimate");
  consdat[,"CN_Estimate"]=apply(consdat[,sp2clone[,"Identity"],drop=F],1,mean)
  return(list(sp2clone=sp2clone, consdat=consdat))
}

.getProfiles<-function(sampleName,perspective){
  map<-getSubclones(sampleName,perspective) 
  vals=c()
  for (e in map){
    vals=cbind(vals, e$getProfile()$simpleValues() )
  }
  rownames(vals)=unlist(e$getProfile()$getLoci())
  colnames(vals)=names(map);
  
  ##Add bulk
  vals=cbind(vals,map[[1]]$getParent()$getProfile()$simpleValues()); 
  colnames(vals)[ncol(vals)]="bulk"
  vals=cbind(vals,parseLOCUS(rownames(vals)))
  return(vals)
}

.getPerspectiveColor<-function(whichP){
  ucols=c("#FF00A8FF","black","cyan","green"); 
  names(ucols)=c("TranscriptomePerspective","GenomePerspective","Identity","ExomePerspective")
  return(ucols[whichP])
}

.rank2<-function(TC){
  if(length(unique(TC))==1){
    TC[T]=0
    return(TC)
  }
  for(v in sort(unique(TC))[2:length(unique(TC))]){
    TC[TC==v]=max(TC[TC<v]+1)
  }
  return(TC)
}
