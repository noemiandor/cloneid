connect2DB <-function(){
  library(RMySQL)
  tmp = suppressWarnings(try(lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)))
  yml = yaml::read_yaml(paste0(system.file(package='cloneid'), '/config/config.yaml'))
  mydb = dbConnect(MySQL(), user=yml$mysqlConnection$user, password=yml$mysqlConnection$password, dbname=yml$mysqlConnection$database,host=yml$mysqlConnection$host, port=as.integer(yml$mysqlConnection$port))
  return(mydb)
}


getAttribute<-function (cloneID, whichP, attr){
  library(RMySQL)
  if(!isempty(grep("_ID",cloneID))){
    cloneID=strsplit(cloneID,"_ID")[[1]][2]
  }
  whichP_=gsub("Genome","",gsub("Transcriptome","",whichP))
  stmt=paste0("select ",attr," from ",whichP_," where whichPerspective='",whichP,"' AND cloneID=",cloneID)
  
  mydb = connect2DB()
  
  rs = dbSendQuery(mydb, stmt)
  o = fetch(rs, n=-1)
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  
  return(o[[attr]])
}


getRootID<-function(sampleName, whichP){
  
  mydb = connect2DB()
  
  whichP_ = gsub("Morphology", "", gsub("Exome", "", gsub("Genome", "", gsub("Transcriptome", "", whichP))))
  stmt = paste0("select cloneID from ", whichP_, " where whichPerspective='",
                whichP, "' AND sampleSource='", sampleName, "' AND parent IS NULL")
  rs = dbSendQuery(mydb, stmt)
  root = fetch(rs, n = -1)
  return (as.numeric(root$cloneID))
}


getCloneColors<-function(sName, whichP = "TranscriptomePerspective",cmap=NULL){
  
  ##Get all clones associeted with this sample
  whichP_=gsub("Exome","",gsub("Genome","",gsub("Transcriptome","",whichP)))
  cloneID = getRootID(sName, whichP)
  
  stmt = paste0("select cloneID from ",whichP_," where parent =",cloneID);
  # stmt=paste0("select children from ",whichP_," where whichPerspective='",whichP,"' AND sampleSource='",sName,"' AND parent IS NULL")
  
  mydb = connect2DB()
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



identity2perspectiveMap <- function (sName, persp, includeSampleOrigin = F) {
  mydb = cloneid::connect2DB()
  stmt = paste0("select cloneID,",persp," from Identity where parent is NOT NULL and sampleSource = '",sName,"'")
  rs = suppressWarnings(dbSendQuery(mydb, stmt))
  la=fetch(rs, n=-1)
  
  persp =la[,persp]
  if (includeSampleOrigin) {
    persp = paste0(sName, ".", persp)
  }
  names(persp) = as.character(la$cloneID)
  return(persp)
}



getPerspectivesPerIdentity <- function(sName, whichP="GenomePerspective"){
  
  mydb = connect2DB()
  
  ##Perspective
  stmt = paste0("select size,cloneID, sampleSource from Perspective where sampleSource like \'%",sName,"%\'");
  rs = dbSendQuery(mydb, stmt)
  p = fetch(rs, n = -1)
  rownames(p) = p$cloneID
  
  ##Identity
  stmt = paste0("select size,cloneID, sampleSource,",whichP," from Identity where sampleSource = \'",sName,"\'");
  rs = dbSendQuery(mydb, stmt)
  i = fetch(rs, n = -1)
  i = i[!is.na(i$GenomePerspective),]
  
  ##Join
  stmt = paste0("select Perspective.size,Identity.cloneID, Perspective.cloneID as PerspectiveID , Perspective.sampleSource  from Identity inner join Perspective on ", 
                "Perspective.cloneID = Identity.",whichP," where Identity.sampleSource =\'",sName,"\'");
  rs = dbSendQuery(mydb, stmt)
  o = fetch(rs, n = -1)
  
  
  ##Complement missing
  missingIDs = lapply(i$GenomePerspective, function(x) setdiff(unlist(strsplit(x,",")), o$PerspectiveID))
  names(missingIDs) = i$cloneID
  missingIDs = missingIDs[!sapply(  missingIDs, isempty)]
  for(id in names(missingIDs)){
    o_ = as.data.frame(matrix(NA,length(missingIDs[[id]]),ncol(o)))
    colnames(o_) = colnames(o)
    o_[,c("size","PerspectiveID","sampleSource")]=p[missingIDs[[id]],]
    o_$cloneID = id
    o = rbind(o, o_)
  }
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  return(o[,c("size","cloneID","sampleSource"), drop=F])
}



countCellsPerIdentity <- function(sName, state="G0G1"){
  mydb = connect2DB()
  stmt = paste0("select TranscriptomePerspective, GenomePerspective from Identity where size<1 and sampleSource=\'",sName,"\'");
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


getCloneMembers<-function(sName, type="Dominant", whichP="GenomePerspective"){
  clones=cloneid::getSubclones(sName,whichP)
  dc=clones[which.max(lapply(names(clones), getSPsize))]
  if(type!="Dominant"){
    dc=clones[names(clones)!=names(dc)]
  }
  dcID=unlist(lapply(names(dc), function(x) strsplit(x,"_ID")[[1]][2]))
  members=lapply(dcID, function(x) cloneid::getSubclones(as.integer(x), whichP))
  members=unlist(members)
  return(members)
}




addSampleSources <- function(src, doublingTime_hours = NA, type = "patient", from = "MoffittCancerCenter"){
  if(is.na(doublingTime_hours)){
    doublingTime_hours = rep(-1, length(src))
  }
  
  mydb = connect2DB();
  for( i in 1:length(src)){
    stmt = paste0("INSERT INTO CellLinesAndPatients  (`name`, `doublingTime_hours`, `whichType`, `source`)",
                  " VALUES (\'", src[i],"\', ", doublingTime_hours[i],", \'", type, "\', \'", from,"\')");
    rs = dbExecute(mydb, stmt)
  }
  dbDisconnect(mydb)
}
