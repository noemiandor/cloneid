getRootID<-function(sampleName, whichP){

  mydb = .connect2DB()
  
  whichP_ = gsub("Exome", "", gsub("Genome", "", gsub("Transcriptome", "", whichP)))
  stmt = paste0("select cloneID from ", whichP_, " where whichPerspective='",
                whichP, "' AND sampleName='", sampleName, "' AND parent IS NULL")
  rs = dbSendQuery(mydb, stmt)
  root = fetch(rs, n = -1)
  return (as.numeric(root$cloneID))
}
