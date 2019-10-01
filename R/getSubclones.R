getSubclones<-function(cloneID_or_sampleName,whichP="GenomePerspective"){

  whichP=J("core.utils.Perspectives")$valueOf(whichP)
  #####################################
  #####Display subclones of a clone:###
  if(class(cloneID_or_sampleName)=="character"){
    x=cloneID_or_sampleName
  }else{
    x=as.integer(cloneID_or_sampleName)
  }
  cs<-.jcall("cloneid.Manager",returnSig ="Ljava/util/Map;",method="display",x,whichP,
             use.true.class=T) 
  # convert Hashmap to R list
  keySet<-.jrcall(cs,"keySet")
  an_iter<-.jrcall(keySet,"iterator")
  aList <- list()
  while(.jrcall(an_iter,"hasNext")){
    key <- .jrcall(an_iter,"next");
    clone=.jrcall(cs,"get",key)
    aList[[key]] <- clone
  }
  return(aList)
}

