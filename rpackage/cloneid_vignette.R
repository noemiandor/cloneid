library(cloneid)
library(gplots)
setwd("~/Repositories/cloneid/data/")
list.files()
[1] "KATOIII_barcodes.tsv" "KATOIII_genes.tsv"   "KATOIII.mtx"          "KATOIII.snv"       "KATOIII.cbs"  

##Genome Perspective
> outG=viewPerspective("KATOIII","GenomePerspective")
[1] "Running ExPANdS on:  KATOIII.snv"
....
Clones scheduled for saving to database:
  1 clone(s) of size 0.23000000417232513
1 clone(s) of size 0.4699999988079071
1 clone(s) of size 0.7300000190734863

##Transcriptome Perspective
> outT=viewPerspective("KATOIII","TranscriptomePerspective")
[1] "Running LIAYSON on:  KATOIII"
....
Clones scheduled for saving to database:
  1 clone(s) of size 0.6060000061988831
1 clone(s) of size 0.39399999380111694
Clones scheduled for saving to database:
  1583 clones of size 3.825554740615189E-4
Clones scheduled for saving to database:
  1031 clone(s) of size 3.825554740615189E-4

##Display transcriptome ploidies
gI=which(apply(!is.na(outT$X$ploidies),2,all))
hm=heatmap.2(outT$X$ploidies[,gI],breaks=c(2:6),trace ="none")
tp=getSubProfiles("KATOIII","TranscriptomePerspective",includeRoot=T)
head(tp)
Clone_0.394_ID6 Clone_0.606_ID5
[1,]        4.003433        2.753177
[2,]        4.076247        2.698310
[3,]        4.061852        2.693854
[4,]             NaN             NaN
[5,]        4.182188        2.772994
[6,]        4.055919        2.683371
cols=c("gray","red","yellow");names(cols)=colnames(tp)
for(cI in colnames(tp)){
  tiff(filename = paste("Ploidy_",cI,".tif",sep=""), width=8.05, height=8, units="in", res=200)
  par(mai=c(2,2,2,2))
  hist(tp[,cI],20,xlab="Ploidy",main=cI,col=cols[cI],xlim=quantile(tp,c(0,1),na.rm=T), cex.lab=2,cex.axis=2)
  dev.off()
}


##Merging perspectives
out=merge(perspective1="GenomePerspective", perspective2="TranscriptomePerspective", "KATOIII",distM=corr)
Clones scheduled for saving to database:
  1 clone(s) of size 0.4320000112056732
1 clone(s) of size 0.6679999828338623
0.668
0.432
> out$sim$euclidean
Clone_0.394_ID6 Clone_0.606_ID5
SP_0.23_ID1      0.03533486      0.02719657
SP_0.47_ID2      0.13291310      0.06312312
SP_0.73_ID3      0.17989215      0.17748980
> out$sp2clone
GenomePerspective TranscriptomePerspective Identity     
6 "SP_0.73_ID3"     "Clone_0.606_ID5"        "Clone_0.668"
2 "SP_0.47_ID2"     "Clone_0.394_ID6"        "Clone_0.432"



##Directly compare Perspectives
display("KATOIII","GenomePerspective",save = T)
display("KATOIII","TranscriptomePerspective",save = T)
display("KATOIII","Identity",save = T)
tiff(filename = paste("KATOIII_CloneIDs_exomeVStranscriptome.tif",sep=""), width=6, height=4, units="in", res=200)
compare(c(20,19),c(91,92),perspective1="GenomePerspective",perspective2="TranscriptomePerspective",col=c("red","blue"))
dev.off()

##Display variuous perspectives on Identity
par(mfrow=c(3,1))
display("KATOIII","Identity",save=T)
display("KATOIII","Identity",colorBy="GenomePerspective",save=T)
display("KATOIII","Identity",colorBy="TranscriptomePerspective",save=T,deep = T)
# display("KATOIII","Identity",colorBy="TranscriptomePerspective>1:300001-108700000", deep=F)
display("KATOIII","Identity",colorBy="TranscriptomePerspective>MKI67,CDK4,CCND1,CDK6", deep=T,save=T)


whichP="TranscriptomePerspective"; prefix="Clone_"
sps=as.data.frame(getSubProfiles("KATOIII",whichP=whichP,includeRoot = T)); 
cols=c("gray","red","yellow");names(cols)=grep(prefix,colnames(sps),value = T)
##Load Karyotype
library(xlsx)
karyo=read.xlsx("~/Projects/PMO/MeasuringGIperClone/discussion/CellLineInfo_JinfengLiuEtAl_SupplTable.xls",sheetName = 2,check.names=F)
rownames(karyo)=karyo$`Cell Line Name`;
spNames=grep(paste(prefix,sep=""),colnames(sps),value = T)
cnPerSP=matrix(NA,length(spNames),22); colnames(cnPerSP)=as.character(c(1:22)); rownames(cnPerSP)=spNames;
##Compare with Karyotype
tmp=strsplit(rownames(sps),":"); tmp2=strsplit(sapply(tmp,"[[",2),"-")
sps$chr=as.numeric(sapply(tmp,"[[",1)); sps$startpos=as.numeric(sapply(tmp2,"[[",1)); sps$endpos=as.numeric(sapply(tmp2,"[[",2))
sps$seglength=1+sps$endpos-sps$startpos
for(sp in grep(prefix,colnames(sps),value = T)){
  tmp=plotCNperChr(sps,cnColumn=sp,startColumn = "startpos", endColumn = "endpos", histograms=F)
  cnPerSP[sp,colnames(tmp)]=tmp
  cnkaryo=as.numeric(karyo["KATOIII",colnames(cnPerSP)])
  ##Plot
  t=cor.test(as.numeric(cnPerSP[sp,]),cnkaryo)
  a=jitter(cnkaryo); b=as.numeric(cnPerSP[sp,]);  
  tiff(filename = paste("KATOIII_KaryoVS",whichP,"_",sp,".tif",sep=""), width=8.5, height=8.65, units="in", res=200)
  par(mai=c(2,2,2,2));plot(a,b,xlab="cytogenetics", ylab=whichP,pch=20,cex=3, cex.lab=2,cex.axis=2,main=paste(sp,": r=",round(t$estimate,2),"; P=",round(t$p.value,3) ),col=cols[sp])
  # lines(c(0,10),c(0,10))
  text(0.999*a,b*0.999,labels = gsub("chr","",colnames(cnPerSP)),cex=0.65)
  dev.off()
}