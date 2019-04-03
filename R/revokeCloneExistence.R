.revokeCloneExistence<-function(o, mydb, sName, whichP){
  if(nrow(o)>0){
    ##Delete clone's children
    to_delete=paste(o[,"cloneID"],collapse=",")
    if(any(!is.na(o[,"children"]))){
      to_delete=paste0(to_delete,",",paste(o[!is.na(o[,"children"]),"children"],collapse = ","))
    }
    stmt = paste0("delete from Perspective where cloneID in (",to_delete,")");
    rs = dbSendQuery(mydb, stmt)
    
    ##Delete clones from parent's children
    stmt = paste0("select cloneID,children from Perspective where sampleName='",sName,
                  "' AND whichPerspective LIKE '",whichP,
                  "' AND parent IS NULL AND size=1");
    rs = dbSendQuery(mydb, stmt)
    q = fetch(rs, n = -1)
    to_keep=setdiff(strsplit(q$children,",")[[1]],o$cloneID)
    stmt = paste0("UPDATE Perspective ",
                  "SET children='", paste(to_keep,collapse = ","),
                  "' WHERE cloneID=",q$cloneID)
    rs = dbSendQuery(mydb, stmt)
  }
}