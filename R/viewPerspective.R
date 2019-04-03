viewPerspective<-function(pathToSample,whichP, tissue=NULL, expandsD="expands", liaysonD="liayson", suffix=".sps.cbs", xy=NULL){
  #   library("rJava")
  #   library(matlab)
  NUMRES=getNumRes()
  expandsD=gsub("~",Sys.getenv("HOME"),expandsD)
  liaysonD=gsub("~",Sys.getenv("HOME"),liaysonD)
  pathToSample=gsub("~",Sys.getenv("HOME"),pathToSample)
  
  sampleName=fileparts(pathToSample)$name
  expandsOut=paste(expandsD,filesep,sampleName,suffix,sep="")
  liaysonOut=paste(liaysonD,filesep,sampleName,suffix,sep="")
  if(!R.utils::isAbsolutePath(expandsD)){
    expandsOut=paste(getwd(),filesep,expandsOut,sep="")
  }
  if(!R.utils::isAbsolutePath(liaysonD)){
    liaysonOut=paste(getwd(),filesep,liaysonOut,sep="")
  }
  
  
  ####################################################################
  ####View clonal composition of a sample from a given perspective###
  gP=J("core.utils.Perspectives")$GenomePerspective
  eP=J("core.utils.Perspectives")$ExomePerspective
  tP=J("core.utils.Perspectives")$TranscriptomePerspective
  kP=J("core.utils.Perspectives")$KaryotypePerspective
  out=NULL;
  if(whichP==gP$name() || whichP==eP$name() || whichP==kP$name()){ ##Exome-seq or Karyotype data
    dir.create(expandsD,showWarnings = F)
    if(!file.exists(expandsOut)){
      out=runExPANdS(paste(pathToSample,".snv",sep=""),paste(pathToSample,".cbs",sep=""),snvF = paste(expandsD,filesep,sampleName,sep=""))
    }else{
      print(paste("Output already exists at:",expandsOut,". Not running EXPANDS."))
    }
    p<-.jnew(paste("core",whichP,sep="."),.jnew("java.io.File", expandsOut),"CN_Estimate") 
  }else if(whichP==tP$name()){
    dir.create(liaysonD,showWarnings = F)
    if(!file.exists(liaysonOut)){
      FILEEXT=".mtx";    mtxFile=paste(pathToSample,FILEEXT,sep="")
      indata <- t(readMM(mtxFile))
      loci <- read.table(file = gsub(FILEEXT,'_genes.tsv',mtxFile),check.names = F,stringsAsFactors = F)
      barcodes <- read.table(file = gsub(FILEEXT,'_barcodes.tsv',mtxFile),check.names = F,stringsAsFactors = F)
      
      X=list(mat=indata, genes=as.character(loci$V2), genes_ensembl=as.character(loci$V1),barcodes=as.character(barcodes$V1), sampleID=sampleName)
      cnSeg=read.table(paste(pathToSample,".cbs",sep=""),sep="\t",header = T,check.names = F,stringsAsFactors = F)
      out=runLIAYSON(X, cnSeg, tissue=tissue)
    }else{
      print(paste("Output already exists at:",liaysonOut,". Not running LIAYSON."))
    }
    p<-.jnew(paste("core",whichP,sep="."),.jnew("java.io.File", liaysonOut),"CN_Estimate") 
  }
  
  ##################
  ####Save to DB####
  if(!is.null(xy)){
    p$setCoordinates(as.double(xy[1]),as.double(xy[2]))
  }
  .jcall(p,returnSig ="V",method = "save2DB")
  if(whichP==tP$name()){
    for(sp in p$getChildrensSizes()){ ##Save subclone profiles
      ##@TODO: save as sparse matrix to DB
       p_<-.jnew("core.TranscriptomePerspective",.jnew("java.io.File", gsub("sps",paste(round(sp,NUMRES),"sps",sep="."),liaysonOut) ),paste("Clone",sp,sep="_"))
      .jcall(p_,returnSig ="V",method = "save2DB")
      ##@TODO: complain if somewthing goes wrong/is incompletely saved! <-- catch exception thrown by java
    }
  }
  if(whichP==gP$name()){
    for(sp in p$getChildrensSizes()){ ##Save subclone profiles
      p_<-.jnew("core.GenomePerspective",.jnew("java.io.File", gsub("sps",paste(round(sp,NUMRES),"sps",sep="."),expandsOut) ),paste("SP",sp,sep="_"))
      .jcall(p_,returnSig ="V",method = "save2DB")
    }
  }
  display(sampleName,whichP)
  
  return(out)
}
