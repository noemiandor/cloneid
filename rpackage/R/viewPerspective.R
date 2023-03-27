viewPerspective<-function(spstatsFile, whichP, suffix=".sps.cbs", xy=NULL){
  #   library("rJava")
  #   library(matlab)
  NUMRES=getNumRes()
  spstatsFile = gsub(suffix, "", spstatsFile, fixed = T);
  clonesDIR=gsub("~",Sys.getenv("HOME"), fileparts(spstatsFile)$pathstr)
  spstatsFile=gsub("~",Sys.getenv("HOME"),spstatsFile)
  
  sampleName=fileparts(spstatsFile)$name
  clonesIn=paste(clonesDIR,filesep,sampleName,suffix,sep="")
  if(!R.utils::isAbsolutePath(clonesDIR)){
    clonesIn=paste(getwd(),filesep,clonesIn,sep="")
  }
  
  ####################################################################
  ####View clonal composition of a sample from a given perspective###
  gP=J("core.utils.Perspectives")$GenomePerspective
  eP=J("core.utils.Perspectives")$ExomePerspective
  tP=J("core.utils.Perspectives")$TranscriptomePerspective
  kP=J("core.utils.Perspectives")$KaryotypePerspective
  mP=J("core.utils.Perspectives")$MorphologyPerspective
  if(!file.exists(clonesIn)){
    print(paste("Clonal composition input does not exists at:",clonesIn,". Run clonal decomposition algorithm first."))
  }
  p<-.jnew(paste("core",whichP,sep="."),.jnew("java.io.File", clonesIn),"CN_Estimate") 
  
  
  ##################
  ####Save to DB####
  if(!is.null(xy)){
    p$setCoordinates(as.double(xy[1]),as.double(xy[2]))
  }
  .jcall(p,returnSig ="V",method = "save2DB")
  if(whichP==tP$name()){
    for(sp in p$getChildrensSizes()){ ##Save subclone profiles
      ##@TODO: save as sparse matrix to DB
      p_<-.jnew("core.TranscriptomePerspective",.jnew("java.io.File", gsub("sps",paste(round(sp,NUMRES),"sps",sep="."),clonesIn) ),paste("Clone",sp,sep="_"))
      .jcall(p_,returnSig ="V",method = "save2DB")
      ##@TODO: complain if somewthing goes wrong/is incompletely saved! <-- catch exception thrown by java
    }
  }
  if(whichP==gP$name()){
    for(sp in p$getChildrensSizes()){ ##Save subclone profiles
      p_<-.jnew("core.GenomePerspective",.jnew("java.io.File", gsub("sps",paste(round(sp,NUMRES),"sps",sep="."),clonesIn) ),paste("SP",sp,sep="_"))
      .jcall(p_,returnSig ="V",method = "save2DB")
    }
  }
  if(whichP==mP$name()){
    for(sp in p$getChildrensSizes()){ ##Save subclone profiles
      p_<-.jnew("core.MorphologyPerspective",.jnew("java.io.File", gsub("sps",paste(round(sp,NUMRES),"sps",sep="."),clonesIn) ),paste("SP",sp,sep="_"))
      .jcall(p_,returnSig ="V",method = "save2DB")
    }
  }
  #display(sampleName,whichP)
}
