
gatherSCprofiles<-function(identities, ccState=NULL, whichP="TranscriptomePerspective"){
  clones=c(); X=c()
  for(i in identities){
    rClone=i$getPerspective(J("core.utils.Perspectives")$valueOf(whichP))
    p=getSubProfiles(rClone$getID(),whichP = whichP)
    state=sapply(colnames(p),getState,whichP)
    if(!is.null(ccState)){
      p=p[,state==ccState, drop=F]
    }
    X=cbind(X,p)
    clones=c(clones,rep(rClone$getID(), ncol(p)))
  }
  names(clones)=colnames(X)
  
  ##Sort by clone size
  sizes=sapply(identities, function(x) x$getPerspective(J("core.utils.Perspectives")$valueOf(whichP))$getSize())
  sizes=sizes[sort(sizes, index.return=T)$ix]
  idx=unlist(lapply(extractID(names(sizes)), function(x) which(clones==x)))
  clones=clones[idx]; X=X[,idx,drop=F]
  
  return(list(X=X,clones=clones))
}
