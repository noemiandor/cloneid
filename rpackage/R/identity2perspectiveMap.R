identity2perspectiveMap<- function(sName,persp, includeSampleOrigin=F){
  identities=cloneid::getSubclones(sName,"Identity")
  tmp=sapply(identities,function(x) x$getPerspective(J("core.utils.Perspectives")$valueOf(persp))$toString())
  persp=sapply(strsplit(names(tmp),"ID"),"[[",2)
  if(includeSampleOrigin){
    persp=paste0(sName,".",persp)
  }
  names(persp)=sapply(strsplit(tmp,"ID"),"[[",2)
  return(persp)
}
