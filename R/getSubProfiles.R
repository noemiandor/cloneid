getSubProfiles<-function (cloneID_or_sampleName, whichP = "TranscriptomePerspective", includeRoot = FALSE) {
  library(RMySQL)
  persp = J("core.utils.Perspectives")$valueOf(whichP)
  whichP_=gsub("Exome","",gsub("Genome","",gsub("Transcriptome","",whichP)))
  
  ##@TODO: doesn't work as expected when using root ID as input --> try accessing parent instead
  if (class(cloneID_or_sampleName) == "character") {
    stmt=paste0("select children from ",whichP_," where whichPerspective='",whichP,"' AND sampleName='",cloneID_or_sampleName,"' AND parent IS NULL")
  }  else {
    stmt=paste0("select children from ",whichP_," where whichPerspective='",whichP,"' AND cloneID=",cloneID_or_sampleName)
  }
  # p <- .jcall("useri.Manager", returnSig = "Ljava/util/Map;", 
  #             method = "profiles", x, persp, includeRoot)
  
  
  mydb = dbConnect(MySQL(), user=Sys.info()["user"], password='lala', dbname='CLONEID',host='127.0.0.1')
  rs = dbSendQuery(mydb, stmt)
  
  kids = fetch(rs, n=-1)
  kids= kids[!is.na(kids)]
  kids =strsplit(kids,",")[[1]]
  if(includeRoot) {
    tmp=cloneID_or_sampleName
    if(is.na(as.numeric(cloneID_or_sampleName))){
      tmp=getRootID(cloneID_or_sampleName, whichP)
    }
    kids = c(tmp, kids)
  }
  # kids=unique(kids)
  dat=c()
  for(kid in  as.integer(kids)){
    p <- .jcall("useri.Manager", returnSig = "Ljava/util/Map;", method = "profile", kid, persp)
    dat = cbind(dat, .javamap2Rmatrix(p))
  }
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  
  return(dat)
}

