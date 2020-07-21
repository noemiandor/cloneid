seed <- function(id, from, cellCount, tx = Sys.time(), dishSurfaceArea_cm2 = 25){
  .seed_or_harvest(event = "seeding", id=id, from = from, cellCount = cellCount, tx = tx, dishSurfaceArea_cm2 = dishSurfaceArea_cm2)
}

harvest <- function(id, from, cellCount, tx = Sys.time(), dishSurfaceArea_cm2 = 25){
  .seed_or_harvest(event = "harvest", id=id, from=from, cellCount = cellCount, tx = tx, dishSurfaceArea_cm2 = dishSurfaceArea_cm2)
}


getPedegreeTree <- function(cellLine){
  library(RMySQL)
  library(ape)

  mydb = .connect2DB()
  stmt = paste0("select * from Passaging where cellLine = '",cellLine,"'");
  rs = suppressWarnings(dbSendQuery(mydb, stmt))
  kids = fetch(rs, n=-1)
  kids= kids[sort(kids$passage, index.return=T)$ix,,drop=F]
  rownames(kids) = kids$id
  
  ## Recursive function to assemble tree
  .gatherDescendands<-function(kids, x){
    ii = which(kids$passaged_from_id1==x)
    if(isempty(ii)){
      return("")
    }
    TREE_ = "("
    for(i in ii){
      y = .gatherDescendands(kids, kids$id[i])
      if(nchar(y)>0){
        y = paste0(y,":1,")
      }
      dx = kids$passage[i]
      TREE_ =paste0(TREE_ , y, kids$id[i],":", dx, ",")
    } 
    TREE_ = gsub(",$",")", TREE_)
    return(TREE_)
  }
  
  ## Assemble tree
  x = kids$id[1]
  TREE_ = .gatherDescendands(kids, x)
  TREE = paste0("(",TREE_, ":1,",x,":1);");

  ## Build tree
  tr <- read.tree(text = TREE)
  str(tr)
  col = c("blue","red")
  names(col) = c("seeding","harvest")
  plot(tr, underscore = T, cex=0.9, tip.color = col[kids[tr$tip.label,]$event])
  legend("topright",names(col),fill=col, bty="n")
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  return(tr)
}



findAllDescendandsOf <-function(ids, includeGR=F){
  library(RMySQL)
  
  mydb = .connect2DB()
  stmt = paste0("select * from Passaging where id IN ",paste0("('",paste0(ids, collapse = "', '"),"')"));
  rs = suppressWarnings(dbSendQuery(mydb, stmt))
  parents = fetch(rs, n=-1)
  
  ## Recursive function to trace descendands
  .traceDescendands<-function(x){
    stmt = paste0("select * from Passaging where passaged_from_id1 = '",x,"'");
    rs = suppressWarnings(dbSendQuery(mydb, stmt))
    kids = fetch(rs, n=-1)
    out = kids$id
    for(id in kids$id){
      out = c(out, .traceDescendands(id))
    }
    return(out)
  }
  
  ## Select statements, appending Ancestor
  out = list();
  for(id in parents$id){
    d = c(id, .traceDescendands(id))
    d = paste0("('",paste0(d, collapse = "', '"),"')")
    if(includeGR){
      out[[id]] = paste0("select P2.*, '",id,"' as Ancestor, DATEDIFF(P2.date, P1.date), POWER(P2.cellCount / P1.cellCount, 1 / DATEDIFF(P2.date, P1.date)) as GR_per_day ", 
                         "FROM Passaging P1 JOIN Passaging P2 ON P1.id = P2.passaged_from_id1 WHERE P2.id IN ",d)
    }else{
      out[[id]] = paste0("select *, '",id,"' as Ancestor from Passaging where id IN ",d);
    }
  }
  
  ## Union
  stmt = out[[1]]
  for(id in setdiff(names(out),names(out)[1])){
    stmt = paste0(stmt, " UNION (", out[[id]],")")
  }
  print(stmt, quote=F)
}



readGrowthRate <- function(cellLine){
  library(RMySQL)
  cmd = paste0("select P2.*, P1.cellCount, P2.cellCount, DATEDIFF(P2.date, P1.date), POWER(P2.cellCount / P1.cellCount, 1 / DATEDIFF(P2.date, P1.date)) as GR_per_day",
               " FROM Passaging P1 JOIN Passaging P2",
               " ON P1.id = P2.passaged_from_id1",
               " WHERE P2.event='harvest' and P1.cellLine='",cellLine,"'") 
  print(cmd, quote = F)
  
  mydb = .connect2DB()
  
  rs = dbSendQuery(mydb, cmd)
  kids = fetch(rs, n=-1)
  tmp = dbClearResult(dbListResults(mydb)[[1]])
  tmp = dbDisconnect(mydb)
  return(kids)
}


populateLiquidNitrogenRacks <-function(rackID){
  library(RMySQL)
  mydb = .connect2DB()
  for(box in 1:13){
    for (br in c('A','B','C','D','E','F','G','H','I')){
      for (bc in 1:9){
        cmd="INSERT INTO LiquidNitrogen (`Rack`, `Row`, `BoxRow`, `BoxColumn`)"
        cmd=paste0(cmd, " VALUES (",rackID,", ",box,", '",br,"', ",bc,");");
        print(cmd,quote = F)
        rs = dbSendQuery(mydb, cmd)
      }
    }
  }
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
}


plotCellLineHistory<-function(){
  library(RMySQL)
  mydb = .connect2DB()
  rs = dbSendQuery(mydb, "select name, year_of_first_report from CellLinesAndBiopsies where year_of_first_report >0;")
  kids = fetch(rs, n=-1)
  
  kids = kids[sort(kids$year_of_first_report, index.return=T)$ix,]
  year = as.numeric(format(Sys.time(), "%Y"))
  par(mai = c(0.85,1,0.5,0.5))
  plot(c(kids$year_of_first_report[1], year), rep(1,2), type="l", ylim=c(0.5,nrow(kids)+0.5), xlab="year", ylab="", yaxt="n", col="blue")
  sapply(2:nrow(kids), function(i) lines(c(kids$year_of_first_report[i], year), rep(i,2), col="blue"))
  axis(2, at=1:nrow(kids), labels=kids$name, las=2)
  # sapply(1:nrow(kids), function(i) lines(c(2017,2018), rep(i,2), col="red", lwd=3))
  # legend("topleft", c("History of cell line", "Sc-Seq experiments"), fill=c("blue","red"))
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
}

updateLiquidNitrogen <- function(id, cellCount, rack, row, boxRow, boxColumn){
  library(RMySQL)
  mydb = .connect2DB()
  cmd=paste0("UPDATE LiquidNitrogen SET ",
                "id = '",id,"',",
                "cellCount = ",cellCount," WHERE ",
                "Rack = '",rack,"' AND ",
                "Row = '",row,"' AND ",
                "BoxRow = '",boxRow,"' AND ",
                "BoxColumn = '",boxColumn,"'");
  print(cmd)
  rs = dbSendQuery(mydb, cmd);
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  
}

removeFromLiquidNitrogen <- function(rack, row, boxRow, boxColumn){
  library(RMySQL)
  mydb = .connect2DB()
  cmd=paste0("UPDATE LiquidNitrogen SET ",
             "id = NULL,",
             "cellCount = 0 WHERE ",
             "Rack = '",rack,"' AND ",
             "Row = '",row,"' AND ",
             "BoxRow = '",boxRow,"' AND ",
             "BoxColumn = '",boxColumn,"'");
  print(cmd)
  rs = dbSendQuery(mydb, cmd);
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
}

.seed_or_harvest <- function(event, id, from, cellCount, tx, dishSurfaceArea_cm2){
  library(RMySQL)
  UM2CM = 1e-4
  QUPATH_DIR="~/QuPath/output/"; ##TODO: should be set under settings, not here
  EVENTTYPES = c("seeding","harvest")
  otherevent = EVENTTYPES[EVENTTYPES!=event]
  
  mydb = .connect2DB()
  
  stmt = paste0("select * from Passaging where id = '",from,"'");
  rs = suppressWarnings(dbSendQuery(mydb, stmt))
  kids = fetch(rs, n=-1)
  
  ### Checks
  if(nrow(kids)==0){
    print(paste(from,"does not exist in table Passaging"), quote = F)
    return()
  }
  if(kids$event !=otherevent){
    print(paste(from,"is not a",otherevent,". You must do",event,"from a",otherevent), quote = F)
    return()
  }
  if(event=="seeding" && !is.na(kids$cellCount) && cellCount>kids$cellCount){
    print("You cannot seed more than is available from harvest!", quote = F)
    return()
  }
  ## TODO: What if from is too far in the past
  
  ## Wait and look for imaging analysis output
  print(paste0("Waiting for ",id,".txt to appear under ",QUPATH_DIR," ..."), quote = F)
  f = paste0(QUPATH_DIR,id,".txt")
  while(!file.exists(f)){
    Sys.sleep(3)
  }
  print(paste0(QUPATH_DIR,id,".txt found!"), quote = F)
  
  ## Read automated image analysis output
  dm = read.table(f,sep="\t", check.names = F, stringsAsFactors = F, header = T)
  margins = apply(dm[,c("Centroid X µm","Centroid Y µm")],2,quantile,c(0,1), na.rm=T)
  plot(dm$`Centroid X µm`,-dm$`Centroid Y µm`)
  rect(margins[1,1], -margins[1,2], margins[2,1], -margins[2,2], col=NULL, border = "red")
  width_height = margins[2,]- margins[1,]
  areaCount = nrow(dm)
  area_um = width_height[1] * width_height[2]; #dm$Area.px.2[dm$Name=="PathAnnotationObject"]
  area2dish = dishSurfaceArea_cm2 / (area_um * UM2CM^2)
  dishCount = round(areaCount * area2dish)
  
  ### Insert
  ## @TODO: event cannot be NULL!
  passage = kids$passage
  if(event=="seeding"){
    passage = passage+1
  }
  stmt = paste0("INSERT INTO Passaging (id, passaged_from_id1, event, date, cellCount, passage) ",
                "VALUES ('",id ,"', '",from,"', '",event,"', '",tx,"', ",dishCount,", ", passage, ");") 
  rs = dbSendQuery(mydb, stmt)
  if(dishCount/cellCount > 2 || dishCount/cellCount <0.5){
    warning(paste0("Automated image analysis deviates from input cell count by more than a factor of 2. CellCount set to the former (",dishCount," cells)"))
  }
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
}

.connect2DB <-function(){
  tmp = suppressWarnings(try(lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)))
  yml = yaml::read_yaml(paste0(system.file(package='cloneid'), '/config/config.yaml'))
  mydb = dbConnect(MySQL(), user=yml$mysqlConnection$user, password=yml$mysqlConnection$password, dbname=yml$mysqlConnection$database,host=yml$mysqlConnection$host, port=as.integer(yml$mysqlConnection$port))
  return(mydb)
}