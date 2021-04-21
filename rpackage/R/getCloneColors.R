getCloneColors<-function(sName, whichP = "TranscriptomePerspective",cmap=NULL){
  
  ##Get all clones associeted with this sample
  whichP_=gsub("Exome","",gsub("Genome","",gsub("Transcriptome","",whichP)))
  cloneID = getRootID(sName, whichP)
  
  stmt = paste0("select cloneID from ",whichP_," where parent =",cloneID);
  # stmt=paste0("select children from ",whichP_," where whichPerspective='",whichP,"' AND sampleName='",sName,"' AND parent IS NULL")

  mydb = .connect2DB()
  rs = dbSendQuery(mydb, stmt)

  # kids = fetch(rs, n=-1)
  # kids= kids[!is.na(kids)]
  # kids =strsplit(kids,",")[[1]]
  # ids=as.numeric(kids)
  # ids=1+ids-min(ids)
  kids = fetch(rs, n=-1)[,"cloneID"]
  ids=1+kids-min(kids)
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  
  ##Get color codes
  ucols=list("Identity"=terrain.colors(max(ids)+2),  
             "TranscriptomePerspective"=rainbow(max(ids)+2),
             "GenomePerspective"=gray.colors(max(ids)+2),
             "ExomePerspective"=heat.colors(max(ids)+2));  
  if(is.null(cmap)){
    thecols=ucols[[whichP]]
  }else{
    f2 <- match.fun(cmap)
    thecols=f2((max(ids)+2))
  }
  set.seed(25)
  cols=sample(thecols,length(thecols))[ids]; names(cols)=as.character(kids)
  return(cols)
}
