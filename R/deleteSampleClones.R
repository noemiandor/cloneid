deleteSampleClones<-function (sampleName, whichTable, whichP = NULL) {
  
  yml = read_yaml(paste0(system.file(package='cloneid'), '/config/config.yaml'))
  mydb = dbConnect(MySQL(), user=yml$mysqlConnection$user, password=yml$mysqlConnection$password, dbname=yml$mysqlConnection$database,host=yml$mysqlConnection$host, port=as.integer(yml$mysqlConnection$port))
  
  stmt = paste0("delete from ", whichTable, " where sampleName='", sampleName, "'")
  
  if (!is.null(whichP)) {
    stmt = paste0(stmt, " AND whichPerspective='", whichP, "'")
  }
  tryCatch({
    rs = dbSendQuery(mydb, stmt)
  }, warning = function(w) {
    warning(w)
  }, error = function(e) {
    print(e)
  }, finally = {
    dbClearResult(dbListResults(mydb)[[1]])
    dbDisconnect(mydb)
  })
}
