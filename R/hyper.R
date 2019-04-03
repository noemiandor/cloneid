hyper<-function(p,r=NULL){
  if (!is.matrix(p) && is.null(r)) 
    stop("supply both 'r' and 'p' or a matrix-like 'p'")
  
  if(is.matrix(p)){
    x=matrix(NA,ncol(p),ncol(p))
    for(i in 1:ncol(p)){
      for(j in 1:ncol(p)){
        x[i,j]=hyper(p[,i],p[,j])
      }
    }
  }else{
    a=.spRelatednessP_oneDirection(p,r); ##Calculates likelihood of observing at least recorded number of common SNVs in SP_p of 2nd clonal composition
    b=.spRelatednessP_oneDirection(r,p); ##Calculates likelihood of observing at least recorded number of common SNVs in SP_r of 1st clonal composition
    x=min(a,b)
  }
  return(x)
}

.spRelatednessP_oneDirection<-function(p,r){
  ##Calculates likelihood of observing at least | M_pr | common SNVs in SP_p
  ii1=which(p>0)##white balls in urn - SNVs in SP_p of 2nd clonal composition
  ij=which(p==0);##black balls in urn - SNVs in other SPs of 2nd clonal composition
  ii2=which(r>0)##balls drawn from urn - SNVs in SP_r of 1st clonal composition 
  o=intersect(ii1,ii2)
  x=phyper(length(o)-1, length(ii1), length(ij), length(ii2)); ##@TODO: double-check this
  return(x)
}