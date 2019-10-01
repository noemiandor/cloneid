.intersect_MatlabV<-function(a,b){
  x=intersect(a,b)
  ia=match(x,a);
  ib=match(x,b);
  return(list(a=x,ia=ia,ib=ib));
}
