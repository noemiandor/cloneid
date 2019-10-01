deleteCloneWithID<-function(cloneid, whichTable, sName) {
  
  yml = read_yaml(paste0(system.file(package='cloneid'), '/config/config.yaml'))
  mydb = dbConnect(MySQL(), user=yml$mysqlConnection$user, password=yml$mysqlConnection$password, dbname=yml$mysqlConnection$database,host=yml$mysqlConnection$host, port=as.integer(yml$mysqlConnection$port))
  stmt = paste0("select cloneID,whichPerspective from ",whichTable," where cloneID=",cloneid);
  
  tryCatch({
    rs = dbSendQuery(mydb, stmt)
    o = fetch(rs, n = -1)
    .revokeCloneExistence(o, mydb, sName, whichP=o$whichPerspective)
  }, warning = function(w) {
    warning(w)
  }, error = function(e) {
    print(e)
  }, finally = {
    dbClearResult(dbListResults(mydb)[[1]])
    dbDisconnect(mydb)
  })
}
