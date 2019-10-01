getSubProfiles<-function (cloneID_or_sampleName, whichP = "TranscriptomePerspective", includeRoot = FALSE) {
  library(RMySQL)
  persp = J("core.utils.Perspectives")$valueOf(whichP)
  whichP_=gsub("Exome","",gsub("Genome","",gsub("Transcriptome","",whichP)))
  
  yml = read_yaml(paste0(system.file(package='cloneid'), '/config/config.yaml'))
  mydb = dbConnect(MySQL(), user=yml$mysqlConnection$user, password=yml$mysqlConnection$password, dbname=yml$mysqlConnection$database,host=yml$mysqlConnection$host, port=as.integer(yml$mysqlConnection$port))
  
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
    p <- .jcall("cloneid.Manager", returnSig = "Ljava/util/Map;", method = "profile", kid, persp)
    dat = cbind(dat, .javamap2Rmatrix(p))
  }
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  
  return(dat)
}

