getRootID<-function(sampleName, whichP){
  mydb = dbConnect(MySQL(), user = Sys.info()["user"], password = "lala", 
                   dbname = "CLONEID", host = "127.0.0.1")
  
  
  whichP_ = gsub("Exome", "", gsub("Genome", "", gsub("Transcriptome", "", whichP)))
  stmt = paste0("select cloneID from ", whichP_, " where whichPerspective='",
                whichP, "' AND sampleName='", sampleName, "' AND parent IS NULL")
  rs = dbSendQuery(mydb, stmt)
  root = fetch(rs, n = -1)
  return (as.numeric(root$cloneID))
}