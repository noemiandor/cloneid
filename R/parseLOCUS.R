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
