merge<-function(perspectives, specimens, simM="euclidean",t=-Inf){
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

.onePerspectiveOnManySpecimens<-function(perspective="GenomePerspective", sampleNames, simM="hyper", t=-Inf){
  ##Get xy coordinates
  coord=matrix(NA,length(sampleNames),2); 
  rownames(coord)=sampleNames; colnames(coord)=c("x","y")
  for(s in sampleNames){
    clones=getSubclones(s,whichP=perspective)
    coord[s,]=clones[[1]]$getCoordinates(); ##
  }
  coord=as.data.frame(coord)
  
  ###########################################################
  ####Establish subpopulation pairs based on coordinates:####
  sOrder=getPathThroughRegions(coord);   coord=coord[sOrder,]
  spPairsAndLinks=c();
  ####Establish pairs of subpopulations to be merged, such that linking the pairs covers all sampled regions exactly once
  for (i in 1:(length(sOrder)-1)){
    spPairsAndLinks=rbind(  spPairsAndLinks,c(sOrder[i],sOrder[i+1]))
  }

  ################################################
  ####Merge the 2 members of each pair/link:#####
  out=list();
  for(i in 1:nrow(spPairsAndLinks)){
    s1=list(); s2=list(); 
    s1[[spPairsAndLinks[i,1]]]=.getProfiles(spPairsAndLinks[i,1],perspective)
    s2[[spPairsAndLinks[i,2]]]=.getProfiles(spPairsAndLinks[i,2],perspective)
    allMut=union(rownames(s1[[1]]),rownames(s2[[1]]))
    
    out1=.mergePair(s1, s2, simM=simM, t=t)
    if(nrow(out1$sp2clone)>0){
      outc=.calculateConsensusProfile(out1$sp2clone,allMut,perspective)
      outc$sp2clone_sim=out1$sp2clone_sim
      
      out[[paste(spPairsAndLinks[i,],collapse = "+")]]=outc
    }else{##None of the subpopulations could be merged
      out[[paste(spPairsAndLinks[i,],collapse = "+")]]=NA
    }
  }
  
  ####################################################################################
  ####Chain reaction <=> transitivity: merge all SPs connected across pairs/links:####
  s=sOrder[1];  buddat=.getProfiles(s,perspective);     sps=grep("SP_",colnames(buddat),value = T)
  sp2clone=matrix(NA,length(sps),length(sOrder)); colnames(sp2clone)=sOrder
  sp2clone_sim=matrix(0,length(sps),length(sOrder)); colnames(sp2clone_sim)=sOrder
  sp2clone[,s]=sps
  allMut=rownames(buddat)
  sampleName=strsplit(s,"*")[[1]]
  usedOrder=s
  for(i in 2:length(sOrder)){
    spair=grep(sOrder[i],grep(sOrder[i-1],names(out),value = T),value = T)
    s2=gsub("\\+","",gsub(s,"",spair))
    # Add merged SP pairs
    if(!is.na(out[[spair]])){
      a=.intersect_MatlabV(sp2clone[,s],out[[spair]]$sp2clone[,s]); 
      sp2clone[a$ia,s2]=out[[spair]]$sp2clone[a$ib,s2]
      sp2clone_sim[a$ia,s2]=out[[spair]]$sp2clone_sim[a$ib,s2]
    }
    ##Add remaining SPs
    buddat=.getProfiles(s2,perspective)
    allMut=c(allMut,rownames(buddat))
    sps2=grep("SP_",colnames(buddat),value = T)
    sps2=setdiff(sps2,sp2clone[,s2])
    if(!isempty(sps2)){
      sp2clone=rbind(matrix(NA,length(sps2),ncol(sp2clone)),sp2clone);
      sp2clone_sim=rbind(matrix(0,length(sps2),ncol(sp2clone)),sp2clone_sim);
      sp2clone[1:length(sps2),s2]=sps2
    }
    s=s2;
    sampleName=LCS(sampleName,strsplit(s,"*")[[1]])$LCS
    usedOrder=c(usedOrder,s);
  }
  allMut=unique(allMut)
  
  ###################################
  ####Calculate consensus genome ####
  out=.calculateConsensusProfile(sp2clone,allMut,perspective)
  out$sp2clone_sim=sp2clone_sim
  out$usedOrder=usedOrder
  
  ##Save output
  sampleName=paste(sampleName,collapse = "")
  outF=paste(getwd(),filesep,sampleName,".identity.sps",sep="")
  outF2=paste(getwd(),filesep,sampleName,".identity.source",sep="")
  write.table(cbind(out$consdat,rownames(out$consdat)),col.names=c(colnames(out$consdat),"LOCUS"),sep="\t",quote=F,file=outF,row.names = F) ##Save as *sps.cbs format
  write.table(out$sp2clone,col.names=c(rep(perspective,ncol(out$sp2clone)-1),"Identity"),sep="\t",quote=F,file=outF2,row.names = F) ##Save as identity source perspectives
  
  ##Upload consensus perspective to DB as identity
  p<-.jnew("core.Identity",.jnew("java.io.File", outF),"CN_Estimate",.jnew("java.io.File", outF2)) 
  print(p)
  .jcall(p,returnSig ="V",method = "save2DB")
  try(display(sampleName,"Identity",))
  return(out)
  
}

.twoPerspectivesOn1Or2Specimens<-function(perspective1="GenomePerspective", perspective2="TranscriptomePerspective", sampleNames, simM="euclidean", t=-Inf){
  # make sure perspective 1 is always genome while 2 is always transcriptome
  perspectives=sort(c(perspective1,perspective2))
  perspective1=perspectives[1]; perspective2=perspectives[2];
  
  #   persp1=J("core.utils.Perspectives")$valueOf(perspective1)
  #   persp2=J("core.utils.Perspectives")$valueOf(perspective2)
  #   p1<-.jcall("useri.Manager",returnSig ="Ljava/util/Map;",method="profiles",sampleNames[1],persp1,includeRoot=FALSE)
  #   p2<-.jcall("useri.Manager",returnSig ="Ljava/util/Map;",method="profiles",sampleNames[2],persp2,includeRoot=FALSE)
  
  ###################################
  #####Compare subclone's profiles###
  s1=list();   s2=list(); 
  s2[[perspective2]]=.getProfiles(sampleNames[2],perspective2)
  s1[[perspective1]]=.getProfiles(sampleNames[1],perspective1)
  ##When s1 and s2 don't share the exact same profile:
  if(nrow(s1[[1]])!=nrow(s2[[1]]) || any(rownames(s1[[1]])!=rownames(s2[[1]]))){
    s=list(); s[[names(s1)]]=s1[[1]]; s[[names(s2)]]=s2[[1]];
    iMost=which.max(sapply(s,nrow)); iFewest=which.min(sapply(s,nrow))
    dm=s[[iMost]][,c("chr","startpos","endpos")]
    cols=c(grep("^Clone",colnames(s[[iFewest]]),value = T),grep("^SP",colnames(s[[iFewest]]),value = T),"bulk")
    for(colN in cols){
      dm= assignQuantityToMutation(dm, s[[iFewest]], quantityColumnLabel = colN) 
    }
    s[[iFewest]]=dm[,cols]
    s1=s[1]; s2=s[2]
  }
  allMut=union(rownames(s1[[1]]),rownames(s2[[1]]))
  
  out1=.mergePair(s2, s1, simM=simM, t=t)
  out=.calculateConsensusProfile(out1$sp2clone,allMut,perspective=NULL)
  out$sp2clone_sim=out1$sp2clone_sim
  out$sim=out1$sim
  out$usedOrder=perspectives
  
  ##Save output
  sampleName=paste(unique(sampleNames),collapse = "")
  outF=paste(getwd(),filesep,sampleName,".identity.sps.cbs",sep="")
  outF2=paste(getwd(),filesep,sampleName,".identity.source",sep="")
  write.table(cbind(out$consdat,rownames(out$consdat)),col.names=c(colnames(out$consdat),"LOCUS"),sep="\t",quote=F,file=outF,row.names = F) ##Save as *sps.cbs format
  write.table(out$sp2clone,sep="\t",quote=F,file=outF2,row.names = F) ##Save as identity source perspectives
  
  ##@TODO: Save consensus perspective to DB as identity
  p<-.jnew("core.Identity",.jnew("java.io.File", outF),"CN_Estimate",.jnew("java.io.File", outF2)) 
  print(p)
  .jcall(p,returnSig ="V",method = "save2DB")
  try(display(sampleName,"Identity"))
  return(out)
}

.mergePair<-function(theone, theother, simM="euclidean", t=-Inf){
  ##Matches clones from two distinct clonal compositions to each other. 
  ##For example, RNA-derived clones to DNA-derived subpopulations based on the distance between their copy number profiles or
  ##DNA-derived subpopulations from two specimens based on the distance between their point mutation profiles.
  ##theone - subpopulation profiles obtained from one perspective (e.g. single-cell RNA-seq data) or specimen
  ##theother - subpopulation profiles obtained from other perspective (e.g. bulk DNA-sequencing data) or specimen
  
  one=theone[[1]]
  two=theother[[1]]
  ii=intersect(rownames(one),rownames(two))
  one=one[ii,,drop=F]; two=two[ii,,drop=F]
  #   colnames(two)=sapply(strsplit(colnames(two),"_ID"),"[[",1)
  #   colnames(one)=sapply(strsplit(colnames(one),"_ID"),"[[",1)
  buspNames=c(unlist(sapply(c("SP_","Clone_"),grep,colnames(two),value=T)),"bulk")
  scspNames=c(unlist(sapply(c("SP_","Clone_"),grep,colnames(one),value=T)),"bulk")
  allNames=c(buspNames,scspNames)
  
  ############################################################################
  ####Calculate pairwise similarity between every clone-subpopulation pair####
  m=matrix(NA,length(buspNames),length(scspNames)); rownames(m)=buspNames; colnames(m)=scspNames
  d=list(euclidean=m, pearson=m, spearman=m, hyper=m)
  for(i in buspNames){
    ia=which(!is.na(two[,i]))
    for(j in scspNames){
      ib=intersect(ia,which(!is.na(one[,j])))
      d$euclidean[i,j]=1/(0.001+dist2(t(two[ib,i,drop=F]),t(one[ib,j,drop=F])))
      d$pearson[i,j]=cor(two[ib,i,drop=F],one[ib,j,drop=F],  method = "pearson")
      d$spearman[i,j]=cor(two[ib,i,drop=F],one[ib,j,drop=F],  method = "spearman")
      #Use hypergeometric distribution for point mutation overlap assessment:
      d$hyper[i,j]=spRelatednessP(two[,i],one[,j]);
    }
  }

  ##########################################################
  ### match clones to subpopulations based on similarity####
  m=d[[simM]]; m=m[-grep("bulk",rownames(m)),-grep("bulk",colnames(m)),drop=F];
  sp2clone=.matchSubpopulations(m,t)
  colnames(sp2clone)=c(names(theother),names(theone))
  
  #########################################
  ### Record similarities of matched SPs####
  sp2clone_sim=matrix(0,nrow(sp2clone),ncol(sp2clone)); 
  rownames(sp2clone_sim)=rownames(sp2clone);
  colnames(sp2clone_sim)=colnames(sp2clone);
  i=1
  while(i <=nrow(sp2clone)){
    sp2clone_sim[i,]=rep(m[sp2clone[i,1],sp2clone[i,2]],ncol(sp2clone_sim))
    i=i+1
  }
  
  out=list(sp2clone=sp2clone, sp2clone_sim=sp2clone_sim, sim=d)
  return(out)
}


.calculateConsensusProfile<-function(sp2clone,allMut,perspective=NULL){
  ###################################
  ####Calculate consensus genome ####
  ##@TODO: the specifics of building the consensus should depend on the perspective
  sp2clone=cbind(sp2clone,matrix(NA,nrow(sp2clone),1)); colnames(sp2clone)[ncol(sp2clone)]="Identity"
  consdat=matrix(0,length(allMut),1+nrow(sp2clone)); rownames(consdat)=allMut
  for(i in 1:nrow(sp2clone)){
    ##Consensus SP size:
    sI=which(!is.na(sp2clone[i,1:(ncol(sp2clone)-1)]))
    x=mean(as.numeric(sapply(sapply(sp2clone[i,sI],strsplit,"_"),"[[",2)))
    sp2clone[i,"Identity"]=paste("Clone_",round(x,3),sep="")
    ##Consensus profile:
    for(j in sI){
      sp=sp2clone[i,j]
      id=strsplit(sp,"ID")[[1]][2]
      if(is.null(perspective)){
        p=.getProfiles(as.numeric(id),colnames(sp2clone)[j]); ##constant region: column label has to denote perspective of each SP in corresponding column
        ##Needed when not all perspectives share the exact same profile:
        id_=paste("SP_",id,sep="")
        colnames(p)=gsub(paste("^",id,"$",sep=""),id_,colnames(p));
        p= assignQuantityToMutation(parseLOCUS(rownames(consdat)), p, quantityColumnLabel = id_) 
      }else{
        id_=id
        p=.getProfiles(as.numeric(id),perspective); ##regional variability: all SPs have same perspective
      }
      consdat[rownames(p),i]=consdat[rownames(p),i]+p[,id_]
    }
    consdat[,i]=consdat[,i]/length(sI)
  }
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