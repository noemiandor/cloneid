getSubProfiles<-function (cloneID_or_sampleName, whichP = "TranscriptomePerspective", includeRoot = FALSE) {
  library(RMySQL)
  persp = J("core.utils.Perspectives")$valueOf(whichP)
  whichP_=gsub("Exome","",gsub("Genome","",gsub("Transcriptome","",whichP)))
  
  mydb = dbConnect(MySQL(), user=Sys.info()["user"], password='lalalala', dbname='CLONEID',host='cloneredesign.cswgogbb5ufg.us-east-1.rds.amazonaws.com')
  
  ##@TODO: doesn't work as expected when using root ID as input --> try accessing parent instead
  if (class(cloneID_or_sampleName) == "character") {
    cloneID = getRootID(cloneID_or_sampleName, whichP)
  }  else {
    cloneID = cloneID_or_sampleName
  }
  
  stmt = paste0("select cloneID from ",whichP_," where parent =",cloneID);
  rs = dbSendQuery(mydb, stmt)
  kids = fetch(rs, n=-1)[,"cloneID"]
  
  # kids= kids[!is.na(kids)]
  # kids =strsplit(kids,",")[[1]]
  if(includeRoot) {
    kids = c(cloneID, kids)
  }
  
  dat=c()
  for(kid in  as.integer(kids)){
    p <- .jcall("useri.Manager", returnSig = "Ljava/util/Map;", method = "profile", kid, persp)
    dat = cbind(dat, .javamap2Rmatrix(p))
  }
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  
  return(dat)
}

