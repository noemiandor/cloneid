getSubProfiles<-function(cloneID_or_sampleName,whichP="TranscriptomePerspective",includeRoot=FALSE){

  persp=J("core.utils.Perspectives")$valueOf(whichP)

  if(class(cloneID_or_sampleName)=="character"){
    x=cloneID_or_sampleName
  }else{
    x=as.integer(cloneID_or_sampleName)
  }
  
  ###################################
  #####Compare subclone's profiles###
  p<-.jcall("useri.Manager",returnSig ="Ljava/util/Map;",method="profiles",x,persp,includeRoot)
  
  dat=.javamap2Rmatrix(p)
  return(dat)

}

