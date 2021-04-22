.javamap2Rmatrix<-function (map){
  keys=c(); vals=c()
  for (e in as.list(map$entrySet())){
    keys=c(keys,e$getKey())
    vals=cbind(vals, e$getValue()$simpleValues() )
  }
  rownames(vals)=unlist(e$getValue()$getLoci())
  colnames(vals)=keys;
  return(vals)
}

parseLOCUS<-function(loci){
  chr=as.numeric(sapply(strsplit(loci,":"),"[[",1))
  startend=sapply(strsplit(loci,":"),"[[",2)
  startp=as.numeric(sapply(strsplit(startend,"-"),"[[",1))
  endp=as.numeric(sapply(strsplit(startend,"-"),"[[",2))
  seglength=1+endp-startp
  dm=cbind(chr,startp,endp,seglength);
  colnames(dm)=c("chr","startpos","endpos","seglength")
  return(dm)
}


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


extractID<-function(cloneString) {  
  x=strsplit(cloneString,"ID") 
  return(sapply(x,function(x) x[min(length(x),2)]))
}

getSPsize<-function(x)  {    
  as.numeric(sapply(strsplit(x,"_"),"[[",2))   
}

getState<-function (cloneID,whichP = "TranscriptomePerspective") {
  return(getAttribute(cloneID, whichP, attr="state"))
}

getAlias<-function (cloneID, whichP = "TranscriptomePerspective") {
  return(getAttribute(cloneID, whichP, attr="alias"))
}
