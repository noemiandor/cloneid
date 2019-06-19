
getPathThroughRegions<-function(coord){
  ##Start with periphery
  start=names(which.min(apply(coord,1,mean)))
  path=c(start)
  while(nrow(coord)>1){
    whatsleft=setdiff(rownames(coord),start)
    ##Get most proximal sample
    d=as.data.frame(dist2(coord[start,],coord[whatsleft,],method = "manhattan")); 
    start=names(which.min(d))
    path=c(path,start)
    coord=coord[whatsleft,]
  }
  return(path)
}
