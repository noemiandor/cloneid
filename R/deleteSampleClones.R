deleteSampleClones<-function (sampleName, whichTable, whichP = NULL) {
  mydb = dbConnect(MySQL(), user=Sys.info()["user"], password='lalalala', dbname='CLONEID',host='cloneredesign.cswgogbb5ufg.us-east-1.rds.amazonaws.com')
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
