getNumRes<-function() {
    return(7)
}

.addColumn<-function(M,newCol,initVal){
  if (!any(colnames(M)==newCol)){
    if(!is.null(dim(M))){
      M=matrix(cbind(M,matrix(initVal,nrow(M),1)),nrow=nrow(M),ncol=ncol(M)+1,
               dimnames = list(rownames(M), c(colnames(M),newCol)));
    }else{
      cols=names(M);
      M=c(M,initVal);
      names(M)=c(cols,newCol);
    }
  }
  return(M);
}

.notifyUser<-function(message,verbose=T){
  if(verbose){
    print(message)
  }
}

.javamap2Rmatrix<-function (map){
  keys=c(); vals=c()
  for (key in as.list(map$keySet())){
    keys=c(keys,key$toString())
    vals=cbind(vals, map$get(key)$simpleValues() )
  }
  rownames(vals)=unlist(map$get(key)$getLoci())
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


assignQuantityToMutation<-function(dm,cbs,quantityColumnLabel="CN_Estimate",verbose=T){
##Add column segmentID to CBS
cols=c("quantityID",quantityColumnLabel,"segmentLength");
if (!any(colnames(cbs)==cols[1])){
    cbs=.addColumn(cbs,cols[1],NA);
    if (any(colnames(cbs)=="Count")){
        cbs[,"quantityID"]=cbs[,"Count"];
    }else{
        cbs[,"quantityID"]=t(1:nrow(cbs));
    }
}

##First add columns to input data if necessary
for (k in 1:length(cols)){
    dm=.addColumn(dm,cols[k],NA);
}
if (!any(colnames(cbs)=="segmentLength")){
    cbs=.addColumn(cbs,"segmentLength",NA);
    cbs[,"segmentLength"]=cbs[,"endpos"]-cbs[,"startpos"];
}

dm=.assignCBSToMutation(dm,cbs,cols,verbose=verbose);

return(dm);
}


.assignCBSToMutation<-function(dm,cbs,cols,verbose){
print("Assigning copy number to mutations...")
##Assign copy numbers in cbs to mutations in dm
for (k in 1:nrow(cbs)){
    if (mod(k,100)==0){
        .notifyUser(paste("Finding overlaps for CBS segment", k,"out of ",nrow(cbs),"..."),verbose=verbose);
    }
    idx=which(dm[,"chr"]==cbs[k,"chr"] & dm[,"startpos"]>=cbs[k,"startpos"] & dm[,"startpos"]<=cbs[k,"endpos"]);
    if (length(idx)==0){
        next;
    }
    ok=which(is.na(dm[idx,"segmentLength"]) | dm[idx,"segmentLength"]>cbs[k,"segmentLength"]);
    if (length(ok)==0){
        next;
    }
    dm[idx[ok],cols]=repmat(cbs[k,cols],length(ok),1);
}
dm=dm[,colnames(dm)!="segmentLength",drop=F];
.notifyUser("... Done.",verbose=verbose)

return(dm);
}


