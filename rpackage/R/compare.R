compare<-function(cloneID1,cloneID2,perspective1="GenomePerspective",perspective2="GenomePerspective",col=NULL,plotType="scatter"){
  # cloneID1=3; perspective1="GenomePerspective"; cloneID2=4; perspective2="GenomePerspective"
  
  if(is.null(col)){
    col=rainbow(length(cloneID1))
  }
  
  ###################################
  #####Compare subclone's profiles###
  mat=c()
  mat2=c()
  for(i in 1:length(cloneID1)){
    c1=getSubclones(cloneID1[i],perspective1)[[1]]
    c2=getSubclones(cloneID2[i],perspective2)[[1]]
    ##sort clones in ascending order of profile size
    sz=list(length=c(c1$getProfile()$size(),c2$getProfile()$size()), clones=c(c1,c2), names=c(c1$toString(),c2$toString()), profiles=c(c1$getProfile(),c2$getProfile()), persp=c(perspective1,perspective2))
    ii=sort(sz$length,index.return=T)$ix
    for(field in names(sz)){
      sz[[field]]=sz[[field]][ii];
    }
    ##Parse profiles: include parent and loci
    for(j in 1:2){
      cs=as.matrix(sz$profiles[[j]]$simpleValues()); rownames(cs)=sz$profiles[[j]]$getLoci(); colnames(cs)=sz$names[j]
      parent=as.matrix(sz$clones[[j]]$getParent()$getProfile()$simpleValues())
      colnames(parent)=sz$clones[[j]]$getParent()$toString()
      cs=cbind(cs,parent,parseLOCUS(rownames(cs)));
      sz$profiles[[j]]=cs
    }
    ##Needed when not all perspectives share the exact same profile:
    p= assignQuantityToMutation(sz$profiles[[2]], sz$profiles[[1]], quantityColumnLabel = sz$names[1]) 
    iSP=sapply(paste("ID",c(cloneID1[i],cloneID2[i]),"$",sep=""),grep,colnames(p)); ##Restore original order
    mat=rbind(mat,cbind(p[,iSP],rep(i,nrow(p),1)))
    mat2=cbind(mat2,p[,c(grep("^SP_1",colnames(p)),iSP)])
  }
  mat2=mat2[,which(!duplicated(colnames(mat2)))]
  if(plotType=="scatter"){
    ii=which(!is.na(mat[,1]) & !is.na(mat[,2]))
    plot(jitter(mat[,1],0.4),jitter(mat[,2],0.4),xlab=perspective1,ylab=perspective2,pch=20,col=col[mat[,3]], main=paste(length(ii),"segments") )
    legend("topleft",paste("Clones ",cloneID1,", ",cloneID2,sep=""),fill=unique(col[mat[,3]]))
  }else if(plotType=="heatmap"){
    ii=which(apply(!is.na(mat2),1,all))
    heatmap.2(mat2[ii,],cexRow = 0.9,cexCol = 0.9,trace = "none",ylab = "LOCUS",Colv = F)
  }
}
