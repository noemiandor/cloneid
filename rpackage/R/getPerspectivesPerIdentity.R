getPerspectivesPerIdentity <- function(sName, whichP="GenomePerspective"){
  
  yml = read_yaml(paste0(system.file(package='cloneid'), '/config/config.yaml'))
  mydb = dbConnect(MySQL(), user=yml$mysqlConnection$user, password=yml$mysqlConnection$password, dbname=yml$mysqlConnection$database,host=yml$mysqlConnection$host, port=as.integer(yml$mysqlConnection$port))

  ##Perspective
  stmt = paste0("select size,cloneID, sampleName from Perspective where sampleName like \'%",sName,"%\'");
  rs = dbSendQuery(mydb, stmt)
  p = fetch(rs, n = -1)
  rownames(p) = p$cloneID
  
  ##Identity
  stmt = paste0("select size,cloneID, sampleName,",whichP," from Identity where sampleName = \'",sName,"\'");
  rs = dbSendQuery(mydb, stmt)
  i = fetch(rs, n = -1)
  i = i[!is.na(i$GenomePerspective),]
  
  ##Join
  stmt = paste0("select Perspective.size,Identity.cloneID, Perspective.cloneID as PerspectiveID , Perspective.sampleName  from Identity inner join Perspective on ", 
                "Perspective.cloneID = Identity.",whichP," where Identity.sampleName =\'",sName,"\'");
  rs = dbSendQuery(mydb, stmt)
  o = fetch(rs, n = -1)
  
  
  ##Complement missing
  missingIDs = sapply(i$GenomePerspective, function(x) setdiff(unlist(strsplit(x,",")), o$PerspectiveID))
  names(missingIDs) = i$cloneID
  missingIDs = missingIDs[!sapply(  missingIDs, isempty)]
  for(id in names(missingIDs)){
    o_ = as.data.frame(matrix(NA,length(missingIDs[[id]]),ncol(o)))
    colnames(o_) = colnames(o)
    o_[,c("size","PerspectiveID","sampleName")]=p[missingIDs[[id]],]
    o_$cloneID = id
    o = rbind(o, o_)
  }
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  return(o[,c("size","cloneID","sampleName"), drop=F])
}