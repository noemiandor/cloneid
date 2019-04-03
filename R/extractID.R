extractID<-function(cloneString) { 
  x=strsplit(cloneString,"ID")
  return(sapply(x,function(x) x[min(length(x),2)])) 
}