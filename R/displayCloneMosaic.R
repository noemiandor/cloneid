.displayCloneMosaic<-function(clones,main="",colorBy=NULL, deep=F, save=F){
  ##Get perspective and loci
  loci=NULL; whichP=NULL
  if(!is.null(colorBy)){
    tmp=strsplit(colorBy,">")[[1]]
    whichP=tmp[1]
    if(length(tmp)>1){
      loci=unlist(strsplit(tmp[2],","))
    }
  }
  
  ##Deep or shallow clonal composition
  if(deep){
    outmap=.displayDeepCloneMosaic(clones,main=main,whichP=whichP, loci=loci, save=save)
  }else{
    outmap=.displayShallowCloneMosaic(clones,main=main,whichP=whichP, loci=loci, save=save)
  }
  return(outmap)
}

.getProfile<-function(clone,whichP="GenomePerspective"){
  p=as.matrix(clone$getProfile()$simpleValues());
  rownames(p)=clone$getProfile()$getLoci();
  return(p)
  
}

.Csamp <- function(n,rad=1,centre=c(0,0)){ 
  x0 <- centre[1] ; y0 <- centre[2] 
  u <- 2*pi*runif(n) 
  r <- sqrt(runif(n)) 
  coord=rad*cbind(x=r*cos(u)+x0, y=r*sin(u)+y0) 
  x=sort(apply(round(2*coord),1,mean),index.return=T)
  return(coord[x$ix,])
} 

.displayShallowCloneMosaic<-function(clones,main="",whichP=NULL, loci=NULL, save=F){
  RESOLUTION=1000; ## Number of cells
  cloneProportions=c()
  for(i in 1:length(clones)){
    cloneProportions[i]= clones[[i]]$getSize()
  }
  cumSPsum=sum(unlist(cloneProportions))
  ##@TODO: sum of clone sizes := 1 should be a requirement (part of "user friedliness")
  cells=1:RESOLUTION
  coord=.Csamp(length(cells))
  ix=sort(cloneProportions,index.return=T)$ix

  dat=c(); grp=c()
  outmap=list()
  for(i in ix){
    clone=clones[[i]]
    cloneSize= clone$getSize()/cumSPsum
    ii=cells[1:round(cloneSize*RESOLUTION)]; #ii=sample(cells,round(cloneSize*RESOLUTION))
    cells=setdiff(cells,ii)
    ##Color code
    colI=i
    if(!is.null(whichP)){
      per=clone$getPerspective(J("core.utils.Perspectives")$valueOf(whichP))
      p=  .getProfile(per,whichP)
      if(!is.null(loci)){
        p=p[loci,,drop=F]
      }
      p=p[!is.na(p),,drop=F]
      colI=.quantify(as.data.frame(p))
    }else{
      colI=round(cloneSize,2)
    }
    dat=rbind(dat,as.matrix(rep(colI,length(ii))))
    grp=c(grp,rep(i,length(ii)))
    outmap[clone$toString()]=colI
  }
  
  ##Plot
  if(save){
    tiff(filename = paste(strsplit(names(clones[1])," ")[[1]][1],"_",main,".",whichP,".tif",sep=""), width=6.55, height=6.65, units="in", res=200)
  }
  .plotCells(coord,dat,grp,loci,names(clones)[ix],main=main)
  if(save){
    dev.off()
  }
  return(outmap)
}

.displayDeepCloneMosaic<-function(clones,main="",whichP=NULL, loci=NULL, save=F){
  RESOLUTION=1000; ## Number of cells
  
  ##Gather profiles
  sampelName="Unknown"
  nCells=0;  
  profiles=list()
  cloneProportions=c()
  for(i in 1:length(clones)){
    clone=clones[[i]]
    sampelName=clone$getSampleName()
    cloneProportions[i]= clone$getSize()
    p=clone$getPerspective(J("core.utils.Perspectives")$valueOf(whichP))
    kids=p$getChildrenIDs();
    kids=sample(kids,round(clone$getSize() *RESOLUTION),replace = T); ##Use identity size, not perspective size
    nCells=nCells+length(kids)
    profiles[[clone$toString()]]=kids
  }
  
  cells=1:nCells
  coord=.Csamp(length(cells))
  ix=sort(cloneProportions,index.return=T)$ix
  
  ##Display cells
  outmap=list()
  dat=c(); grp=c();
  for(k in ix){
    clone=clones[[k]]
    kids=profiles[[clone$toString()]]
    ii=cells[1:length(kids)]; #ii=sample(cells,round(cloneSize*RESOLUTION))
    cells=setdiff(cells,ii)
    for(i in ii){
      sp=getSubclones(as.integer(kids[i==ii]),whichP)[[1]]
      spr=.getProfile(sp)
      if(!is.null(loci)){
        spr=spr[loci,,drop=F]
      }
      colI=1+round(apply(spr,2,sum)*10)
      dat=rbind(dat,rep(colI,1))
      outmap[sp$toString()]=colI
    }
    grp=c(grp,rep(k,length(ii)))
  }
  ##Plot
  if(save){
    tiff(filename = paste(sampelName,"_",main,".",whichP,".tif",sep=""), width=6.55, height=6.65, units="in", res=200)
  }
  .plotCells(coord,dat,grp,loci,names(clones)[ix],main=main)
  if(save){
    dev.off()
  }
  return(outmap)
}

.quantify<-function(x){
#   if(all(grepl(":",rownames(x))) && all(grepl("-",rownames(x)))){
#     tmp=strsplit(rownames(x),":")
#     x$chr=as.numeric(sapply(tmp,"[[",1))
#     tmp=strsplit(sapply(tmp,"[[",2),"-")
#     x$startpos=as.numeric(sapply(tmp,"[[",1))
#     x$endpos=as.numeric(sapply(tmp,"[[",2))
#     x$seglength=1+x$endpos-x$startpos
#     x=.getInnermostSegments(x)
#     ploidy=x[,1]*x$seglength
#     ploidy=sum(ploidy,na.rm = T)/sum(x$seglength[!is.na(x[,1])])
#     return(ploidy)
#   }else{
    return(mean(x[,1],na.rm=T))
  # }
}

.plotCells<-function(coord,dat,grp1,loci,cloneNames,main){
  mypal <- rev(colorRampPalette(brewer.pal(11,"Spectral")[2:10])(256))
  par(mar=c(4.1, 3.9, 4.1, 2.1),bg="white",fg="black",col.axis="black",col.lab="black",col.main="black",col.sub="black")
  layout(matrix(1:2,ncol=2), widths = c(5,1),heights = c(1,1))
  mycolors <- mypal[as.numeric(cut(as.matrix(dat),breaks = 256))]
  clonePch=c(15,10,16,11,17,12,18,13,1,14,2,3)
  plot(coord,col="black",cex=1.2,pch=clonePch[grp1],xlim=c(-1,1.3),main=strsplit(main,">")[[1]][1]) 
  points(coord,col=mycolors,pch=clonePch[grp1])
  legend("topright",cloneNames,pch=unique(clonePch[grp1]),cex=1.4,pt.cex=2.5,bg = "white")
  par(mar=c(6,1,6,3))
  image(1,seq(round(min(dat),2),round(max(dat),2),len=256),matrix(1:256,nrow=1),col=mypal,axes=FALSE,xlab="",ylab="",main=loci)
  axis(2)
}

##Get only mutually non-overlapping CBS segments
.getInnermostSegments<-function(cnSeg){
  iK=c()
  for(i in 1:nrow(cnSeg)){
    ##Any segments embedded in this segment?
    ii=which(cnSeg$chr==cnSeg$chr[i] & cnSeg$startpos>cnSeg$startpos[i] 
             & cnSeg$endpos<=cnSeg$endpos[i])
    ii=union(ii, which(cnSeg$chr==cnSeg$chr[i] & cnSeg$startpos>=cnSeg$startpos[i] 
                       & cnSeg$endpos<cnSeg$endpos[i]))
    if(isempty(ii)){
      iK=c(iK,i)
    }
    
  }
  return(cnSeg[iK,])
}


