display<-function(cloneID_or_sampleName,whichP="GenomePerspective",colorBy=NULL,deep=F,save=F){
  aList=getSubclones(cloneID_or_sampleName,whichP=whichP)
  outmap=.displayCloneMosaic(aList,main=paste(whichP,colorBy),colorBy=colorBy,deep=deep,save=save)
  return(outmap)
}
