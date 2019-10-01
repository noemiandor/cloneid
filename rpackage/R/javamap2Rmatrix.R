.javamap2Rmatrix<-function (map){
  keys=c(); vals=c()
  for (e in as.list(map$entrySet())){
    keys=c(keys,e$getKey())
    vals=cbind(vals, e$getValue()$simpleValues() )
  }
  rownames(vals)=unlist(e$getValue()$getLoci())
  colnames(vals)=keys;
  return(vals)
}
