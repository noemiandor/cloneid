.matchSubpopulations<-function(similarityMat, t=-Inf){
  if(prod(dim(similarityMat))<9){
    ###############################################################################
    ####Exhaustive search to match clones to subpopulations based on similarity####
    allCombi=expand.grid(rownames(similarityMat),colnames(similarityMat),stringsAsFactors = F)
    opt=list()
    ii=permutations(nrow(allCombi),nrow(allCombi))
    for(p in 1:size(ii,1)){
      aC=allCombi[ii[p,],]
      s=0; combi=c()
      while(!all(is.na(aC))){
        combi=rbind(combi,aC[1,,drop=F])
        s=s+similarityMat[aC[1,1],aC[1,2]]
        aC=aC[aC[,1]!=aC[1,1] & aC[,2]!=aC[1,2],,drop=F]; ##exclude used ones
      }
      opt[[as.character(s)]]=combi
    }
    choiceI=which.max(as.numeric(names(opt)))
    sp2clone=as.matrix(opt[[choiceI]]); 
    
    ##Exclude pairs where SPs are not similar enough to be matched
    toK=c()
    for(i in 1:nrow(sp2clone)){
      if(similarityMat[sp2clone[i,1], sp2clone[i,2]]>=t){
        toK=c(toK,i)
      }
    }
    sp2clone=sp2clone[toK,,drop=F]
    
  }else{
    ###############################################################################
    ####Greedy heuristic: when exhaustive search doesn't scale (>= 4 clones/SPs)###
    ##@TODO: better heuristic than greedy needed
    n=min(dim(similarityMat))
    sp2clone=c()
    while(any(!is.na(similarityMat))){
      o=.whichMaxMatlab(similarityMat)
      x=names(c(o$iRow,o$iCol))
      if(similarityMat[o$iRow,o$iCol]<t){ ##SPs not similar enough to be matched
        break
      }
      sp2clone=rbind(sp2clone,x)
      toD=intersect(rownames(similarityMat),x);
      similarityMat[toD,]=NA; 
      toD=intersect(colnames(similarityMat),x);
      similarityMat[,toD]=NA;
    }
  } 
  return(sp2clone)
}

.whichMaxMatlab<-function(pvals,na.rm=T){
  
  
  # Return max col index
  iC=which.max(apply(pvals,MARGIN=2,max,na.rm=na.rm))
  
  # Return max row index
  iR=which.max(apply(pvals,MARGIN=1,max,na.rm=na.rm))
  
  return(list(iRow=iR,iCol=iC))
}