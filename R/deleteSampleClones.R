deleteSampleClones<-function (sampleName, whichTable, whichP = NULL) {
  mydb = dbConnect(MySQL(), user=Sys.info()["user"], password='lala', dbname='CLONEID',host='127.0.0.1')
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