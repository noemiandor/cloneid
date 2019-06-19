deleteClones<-function(belowSize=0.02, aboveSize=NA, sName, whichP="TranscriptomePerspective"){
  ##deletes parental clones belwo specified size and all their children
  ##@TODO: make sure deleted clones are not referenced in Identity table
  if(whichP=="Identity"){
    print("Deleting identities is not allowed.")
    return()
  }
  
  mydb = dbConnect(MySQL(), user=Sys.info()["user"], password='lalalala', dbname='CLONEID',host='cloneredesign.cswgogbb5ufg.us-east-1.rds.amazonaws.com')
  tryCatch({
    if(!is.na(belowSize)){
      .doTheWork(mydb, belowSize=belowSize, aboveSize=NA, sName, whichP)
    }
    if(!is.na(aboveSize)){
      .doTheWork(mydb, belowSize=NA, aboveSize=aboveSize, sName, whichP)
    }
  }, warning = function(w) {
    warning(w)
  }, error = function(e) {
    print(e)
  }, finally = {
    ##Clean up
    dbClearResult(dbListResults(mydb)[[1]])
    dbDisconnect(mydb)
  })
}



.doTheWork<-function(mydb, belowSize, aboveSize, sName, whichP){
  ##Direct children of root (i.e. first generation tumor clones)
  stmt = paste0("select cloneID from Perspective where sampleName='",sName,
                "' AND whichPerspective='",whichP,
                "' AND parent IS NULL");
  ##Select what to delete:
  rs = dbSendQuery(mydb, stmt)
  o = fetch(rs, n = -1)
  stmt = paste0("select cloneID from Perspective where parent =",o$cloneID);
  
  if(!is.na(belowSize)){
    stmt = paste0(stmt," AND size<=",belowSize)
  }
  if(!is.na(aboveSize)){
    stmt = paste0(stmt," AND size>=",aboveSize)
  }
  rs = dbSendQuery(mydb, stmt)
  o = fetch(rs, n = -1)
  print(paste("Deleting",nrow(o),whichP,"clones from table Perspective:", paste(o$cloneID,collapse=",")));
  
  
  .revokeCloneExistence(o, mydb, sName, whichP)
}
