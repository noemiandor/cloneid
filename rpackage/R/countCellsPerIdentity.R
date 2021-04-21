countCellsPerIdentity <- function(sName, state="G0G1"){
  mydb = .connect2DB()
  stmt = paste0("select TranscriptomePerspective, GenomePerspective from Identity where size<1 and sampleName=\'",sName,"\'");
  rs = dbSendQuery(mydb, stmt)
  kids = fetch(rs, n = -1)
  kids$GenomePerspective_Size <- kids$TranscriptomePerspective_Size <- NA
  ##Genome
  for(kid in kids$GenomePerspective){
    stmt = paste0("select count(size) from Perspective where state= \'",state,"\' and parent=",kid);
    rs = dbSendQuery(mydb, stmt)
    kids$GenomePerspective_Size[kids$GenomePerspective==kid]=fetch(rs, n = -1)
  }
  ##Transcriptome
  for(kid in kids$TranscriptomePerspective){
    stmt = paste0("select count(size) from Perspective where state= \'",state,"\' and parent=",kid);
    rs = dbSendQuery(mydb, stmt)
    kids$TranscriptomePerspective_Size[kids$TranscriptomePerspective==kid]=fetch(rs, n = -1)
  }
  kids$sName=sName
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  return(kids)
}
