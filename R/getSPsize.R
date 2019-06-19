getSPsize<-function(x)  {    as.numeric(sapply(strsplit(x,"_"),"[[",2))   }
