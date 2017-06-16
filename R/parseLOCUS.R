parseLOCUS<-function(loci){
  
  chr=as.numeric(sapply(strsplit(loci,":"),"[[",1))
  startend=sapply(strsplit(loci,":"),"[[",2)
  startp=as.numeric(sapply(strsplit(startend,"-"),"[[",1))
  endp=as.numeric(sapply(strsplit(startend,"-"),"[[",2))
  dm=cbind(chr,startp,endp);
  colnames(dm)=c("chr","startpos","endpos")
  return(dm)
}