deleteCloneWithID<-function(cloneid, whichTable, sName) {
  mydb = dbConnect(MySQL(), user = Sys.info()["user"], password = "lala", 
                   dbname = "CLONEID", host = "127.0.0.1")
  stmt = paste0("select cloneID,children,whichPerspective from ",whichTable," where cloneID=",cloneid);
  
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