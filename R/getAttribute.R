.getAttribute<-function (cloneID, whichP, attr){
  library(RMySQL)
  if(!isempty(grep("_ID",cloneID))){
    cloneID=strsplit(cloneID,"_ID")[[1]][2]
  }
  whichP_=gsub("Genome","",gsub("Transcriptome","",whichP))
  stmt=paste0("select ",attr," from ",whichP_," where whichPerspective='",whichP,"' AND cloneID=",cloneID)
  
  mydb = dbConnect(MySQL(), user=Sys.info()["user"], password='lalalala', dbname='CLONEID',host='cloneredesign.cswgogbb5ufg.us-east-1.rds.amazonaws.com')
  rs = dbSendQuery(mydb, stmt)
  o = fetch(rs, n=-1)
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  
  return(o[[attr]])
}


