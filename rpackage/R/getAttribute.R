.getAttribute<-function (cloneID, whichP, attr){
  library(RMySQL)
  if(!isempty(grep("_ID",cloneID))){
    cloneID=strsplit(cloneID,"_ID")[[1]][2]
  }
  whichP_=gsub("Genome","",gsub("Transcriptome","",whichP))
  stmt=paste0("select ",attr," from ",whichP_," where whichPerspective='",whichP,"' AND cloneID=",cloneID)
  
  yml = read_yaml(paste0(system.file(package='cloneid'), '/config/config.yaml'))
  mydb = dbConnect(MySQL(), user=yml$mysqlConnection$user, password=yml$mysqlConnection$password, dbname=yml$mysqlConnection$database,host=yml$mysqlConnection$host, port=as.integer(yml$mysqlConnection$port))
  
  rs = dbSendQuery(mydb, stmt)
  o = fetch(rs, n=-1)
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  
  return(o[[attr]])
}


