deleteCloneWithID<-function(cloneid, whichTable, sName) {
  mydb = dbConnect(MySQL(), user = Sys.info()["user"], password = "lalalala", 
                   dbname = "CLONEID", host = "cloneredesign.cswgogbb5ufg.us-east-1.rds.amazonaws.com")
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
