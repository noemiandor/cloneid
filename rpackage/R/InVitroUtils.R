seed <- function(id, from, cellCount, flask, tx = Sys.time(), media=NULL, excludeOption=F, preprocessing=T, param=NULL){ 
  x=.seed_or_harvest(event = "seeding", id=id, from = from, cellCount = cellCount, tx = tx, flask = flask, media = media, excludeOption=excludeOption, preprocessing=preprocessing, param=param)
  return(x)
}


harvest <- function(id, from, cellCount, tx = Sys.time(), media=NULL, excludeOption=F, preprocessing=T, param=NULL){
  x=.seed_or_harvest(event = "harvest", id=id, from=from, cellCount = cellCount, tx = tx, flask = NULL, media = media, excludeOption=excludeOption, preprocessing=preprocessing, param=param)
  return(x)
}

inject <- function(mouseID, from, cellCount, tx = Sys.time(), strain, injection_type=23){ 
  x=.seed_or_harvest(event = "seeding", id=mouseID, from = from, cellCount = cellCount, tx = tx, flask = injection_type, media = strain, excludeOption=F, preprocessing=F, param=NULL,inject=injection_type)
}

resect <- function(id, from, weight_mg, size_cubicmm, tx = Sys.time()){
  x=.seed_or_harvest(event = "harvest", id=id, from=from, cellCount = size_cubicmm, tx = tx, flask = NULL, media = NULL, excludeOption=F, preprocessing=F, param=NULL, resect=weight_mg)
  return(x)
}

init <- function(id, cellLine, cellCount, tx = Sys.time(), media=NULL, flask=NULL, preprocessing=T){
  mydb = connect2DB()
  
  dishCount = cellCount;
  if(!is.null(flask)){
    dishSurfaceArea_cm2 = .readDishSurfaceArea_cm2(flask, mydb)
    dishCount = .readCellSegmentationsOutput(id= id, from=cellLine, cellLine = cellLine, dishSurfaceArea_cm2 = dishSurfaceArea_cm2, cellCount = cellCount, preprocessing=preprocessing)$dishCount;
  }
  if(is.null(media)){
    media = "NULL"
  }
  if(is.null(flask)){
    flask = "NULL"
  }
  
  rs = suppressWarnings(dbSendQuery(mydb, "SELECT user()"));
  user=fetch(rs, n=-1)[,1];
  
  stmt = paste0("INSERT INTO Passaging (id, cellLine, event, date, cellCount, passage, flask, media, owner, lastModified) ",
                "VALUES ('",id ,"', '",cellLine,"', 'harvest', '",as.character(tx),"', ",dishCount,", ", 1,", ",flask,", ", media, ", '", user, "', '", user, "');")
  rs = dbSendQuery(mydb, stmt)
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
}


feed <- function(id, tx=Sys.time()){
  library(RMySQL)
  mydb = connect2DB()
  
  stmt = paste0("select * from Passaging where id = '",id,"'");
  rs = suppressWarnings(dbSendQuery(mydb, stmt))
  kids = fetch(rs, n=-1)
  
  ### Checks
  if (kids$event=="harvest"){
    print("Cannot feed cells that have already been harvested.", quote = F); 
    return();
  }
  
  priorfeedings = kids[grep("feeding",names(kids),value=T)]
  ## Next un-occupied feeding index
  nextI = apply(!is.na(priorfeedings),1,sum)+1
  if(nextI>length(priorfeedings)){
    print(paste0("Cannot record more than ",length(priorfeedings)," feedings. Add additional feeding column first."), quote = F); 
    return()
  }
  
  ### Insert
  stmt = paste0("UPDATE Passaging SET ",names(priorfeedings)[nextI]," = '",as.character(tx),"' where id = '",id ,"'") 
  rs = dbSendQuery(mydb, stmt)
  print(paste("Feeding for",id,"recorded at",tx), quote = F);
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
}

## Read dishSurfaceArea_cm2 of this flask 
.readDishSurfaceArea_cm2 <- function(flask, mydb = NULL){
  if(is.null(mydb)){
    mydb = connect2DB()
  }
  stmt = paste0("select dishSurfaceArea_cm2 from Flask where id = ", flask)
  rs = suppressWarnings(dbSendQuery(mydb, stmt))
  dishSurfaceArea_cm2 = fetch(rs, n=-1)
  if(nrow(dishSurfaceArea_cm2)==0){
    print("Flask does not exist in database or its surface area is not specified")
    stopifnot(nrow(dishSurfaceArea_cm2)>0)
  }
  return(dishSurfaceArea_cm2[[1]])
}


getPedigreeTree <- function (cellLine = cellLine, id = NULL, cex = 0.5){
  library(RMySQL)
  library(ape)
  if (is.null(id)) {
    mydb = connect2DB()
    stmt = paste0("select * from Passaging where cellLine = '", 
                  cellLine, "'")
    rs = suppressWarnings(dbSendQuery(mydb, stmt))
    kids = fetch(rs, n = -1)
    dbClearResult(dbListResults(mydb)[[1]])
    dbDisconnect(mydb)
  } else {
    kids = findAllDescendandsOf(id)
  }
  kids = kids[sort(kids$date, index.return = T)$ix, , drop = F]
  kids = kids[sort(kids$passage, index.return = T)$ix, , drop = F]
  rownames(kids) = kids$id
  .gatherDescendands <- function(kids, x) {
    ii = grep(paste0("^",x,"$"), kids$passaged_from_id1, ignore.case = T )
    if (isempty(ii)) {
      return("")
    }
    TREE_ = "("
    for (i in ii) {
      y = .gatherDescendands(kids, kids$id[i])
      if (nchar(y) > 0) {
        y = paste0(y, ":1,")
      }
      dx = kids$passage[i]
      TREE_ = paste0(TREE_, y, kids$id[i], ":", dx, ",")
    }
    TREE_ = gsub(",$", ")", TREE_)
    return(TREE_)
  }
  x = kids$id[1]
  TREE_ = .gatherDescendands(kids, x)
  TREE = paste0("(", TREE_, ":1,", x, ":1);")
  tr <- read.tree(text = TREE)
  str(tr)
  col = c("blue", "red")
  names(col) = c("seeding", "harvest")
  plot(tr, underscore = T, cex = cex, tip.color = col[kids[tr$tip.label, 
  ]$event])
  legend("topright", names(col), fill = col, bty = "n")
  return(tr)
}


findAllDescendandsOf <-function(ids, mydb = NULL, recursive = T, verbose = T){
  library(RMySQL)
  
  if(is.null(mydb)){
    mydb = connect2DB()
  }
  stmt = paste0("select * from Passaging where id IN ",paste0("('",paste0(ids, collapse = "', '"),"')  order by date DESC"));
  rs = suppressWarnings(RMySQL::dbSendQuery(mydb, stmt))
  parents = fetch(rs, n=-1)
  
  ## Recursive function to trace descendands
  .traceDescendands<-function(x){
    stmt = paste0("select * from Passaging where passaged_from_id1 = '",x,"'");
    rs = suppressWarnings(RMySQL::dbSendQuery(mydb, stmt))
    kids = fetch(rs, n=-1)
    out = kids$id
    if(recursive){
      for(id in kids$id){
        out = c(out, .traceDescendands(id))
      }
    }
    return(out)
  }
  
  ## Select statements, appending Ancestor
  alllineages = c()
  out = list();
  for(id in parents$id){
    d = c(id, .traceDescendands(id))
    d = setdiff(d, alllineages); ## exclude descendands with more recent parent (i.e. seedings)
    alllineages = c(alllineages, d)
    d = paste0("('",paste0(d, collapse = "', '"),"')")
    out[[id]] = paste0("select *, '",id,"' as Ancestor from Passaging where id IN ",d);
  }
  
  ## Union
  stmt = out[[1]]
  for(id in setdiff(names(out),names(out)[1])){
    stmt = paste0(stmt, " UNION (", out[[id]],")")
  }
  if(verbose){
    print(stmt)
  }
  
  ## Get results from DB
  rs = suppressWarnings(RMySQL::dbSendQuery(mydb, stmt))
  res = fetch(rs, n=-1)
  
  dbDisconnect(mydb)
  
  return(res)
}



readGrowthRate <- function(cellLine){
  library(RMySQL)
  cmd = paste0("select P2.*, P1.cellCount, P2.cellCount, DATEDIFF(P2.date, P1.date), POWER(P2.cellCount / P1.cellCount, 1 / DATEDIFF(P2.date, P1.date)) as GR_per_day",
               " FROM Passaging P1 JOIN Passaging P2",
               " ON P1.id = P2.passaged_from_id1",
               " WHERE P2.event='harvest' and P1.cellLine='",cellLine,"'") 
  print(cmd, quote = F)
  
  mydb = connect2DB()
  
  rs = dbSendQuery(mydb, cmd)
  kids = fetch(rs, n=-1)
  tmp = dbClearResult(dbListResults(mydb)[[1]])
  tmp = dbDisconnect(mydb)
  return(kids)
}


populateLiquidNitrogenRacks <-function(rackID){
  library(RMySQL)
  mydb = connect2DB()
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
  mydb = connect2DB()
  rs = dbSendQuery(mydb, "select name, year_of_first_report, doublingTime_hours from CellLinesAndPatients where year_of_first_report >0;")
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
  return(kids)
}

updateLiquidNitrogen <- function(id, cellCount, rack, row, boxRow, boxColumn){
  library(RMySQL)
  mydb = connect2DB()
  cmd=paste0("UPDATE LiquidNitrogen as x SET ",
             "x.id = '",id,"',",
             "x.cellCount = ",cellCount," WHERE ",
             "x.Rack = '",rack,"' AND ",
             "x.Row = '",row,"' AND ",
             "x.BoxRow = '",boxRow,"' AND ",
             "x.BoxColumn = '",boxColumn,"'");
  print(cmd)
  rs = dbSendQuery(mydb, cmd);
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  
}

removeFromLiquidNitrogen <- function(rack, row, boxRow, boxColumn){
  library(RMySQL)
  mydb = connect2DB()
  cmd=paste0("UPDATE LiquidNitrogen as x SET ",
             "x.id = NULL,",
             "x.cellCount = 0 WHERE ",
             "x.Rack = '",rack,"' AND ",
             "x.Row = '",row,"' AND ",
             "x.BoxRow = '",boxRow,"' AND ",
             "x.BoxColumn = '",boxColumn,"'");
  print(cmd)
  rs = dbSendQuery(mydb, cmd);
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
}

plotLiquidNitrogenBox <- function (rack, row) {
  library(RMySQL)
  mydb = connect2DB()
  cmd = paste0("select * from LiquidNitrogen as x where ", "x.Rack = '", 
               rack, "' AND ", "x.Row = '", row,"'")
  print(cmd)
  rs = dbSendQuery(mydb, cmd)
  kids = fetch(rs, n = -1)
  kids$id[is.na(kids$id)] = "NA"
  rc = apply(kids, 2, unique)
  par(mfrow = c(2, 2), mai = c(0, 0.5, 0.5, 0))
  plot(c(1, length(rc$BoxColumn)), c(1, length(rc$BoxRow)), 
       col = "white", yaxt = "n", xaxt = "n", xlab = "", ylab = "", 
       main = paste("Rack", rack, "; Row", row), ylim = rev(range(c(1, 
                                                                    length(rc$BoxRow)))))
  axis(1, at = 1:length(rc$BoxColumn), labels = rc$BoxColumn, 
       las = 1)
  axis(2, at = 1:length(rc$BoxRow), labels = rc$BoxRow, las = 2)
  cols = gray.colors(length(rc$id) * 1.2)[1:length(rc$id)]
  names(cols) = unique(rc$id)
  cols["NA"] = "white"
  for (i in 1:nrow(kids)) {
    points(match(kids$BoxColumn[i], rc$BoxColumn), match(kids$BoxRow[i], 
                                                         rc$BoxRow), col = cols[kids$id[i]], pch = 20, cex = 4)
  }
  plot(1, 1, axes = F, col = "white")
  legend("topleft", names(cols), fill = cols)
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
}


.seed_or_harvest <- function(event, id, from, cellCount, tx, flask, media, excludeOption, preprocessing=T, param=NULL, inject=NULL, resect=NULL){
  library(RMySQL)
  library(matlab)
  
  EVENTTYPES = c("seeding","harvest")
  otherevent = EVENTTYPES[EVENTTYPES!=event]
  
  mydb = connect2DB()
  
  stmt = paste0("select * from Passaging where id = '",from,"'");
  rs = suppressWarnings(dbSendQuery(mydb, stmt))
  parent = fetch(rs, n=-1)
  
  ### Checks
  CHECKRESULT="pass"
  if(nrow(parent)==0){
    CHECKRESULT=paste(from,"does not exist in table Passaging")
  }else if(parent$event !=otherevent){
    CHECKRESULT=paste(from,"is not a",otherevent,". You must do",event,"from a",otherevent)
  }else if(event=="seeding" && !is.na(parent$cellCount) && !is.na(cellCount) && cellCount>parent$cellCount){
    CHECKRESULT="You cannot seed more than is available from harvest!"
  }else if(is.na(parent$media) || !is.null(media)){
    if(is.null(media)){
      CHECKRESULT="Please enter media information"
    }else{
      parent$media = media
    }
  }else{
    warning(paste("Copying media information from parent: media set to",parent$media))
  }
  if(CHECKRESULT!="pass"){
    confirmError = "no"
    while(confirmError!="yes"){
      confirmError <- readline(prompt=paste0("Error encountered while updating database: ",CHECKRESULT,". No changes were made to the database. Type yes to confirm: "))
    }
    return()
  }
  ## TODO: What if from is too far in the past
  
  ## flask cannot have changed if this is a harvest event: 
  if(event=="harvest"){
    flask = parent$flask
  }
  
  if(!is.null(inject)){
    dish =list(dishCount=cellCount, cellSize=NA, dishAreaOccupied=NA)
  }else if (!is.null(resect)){
    dish =list(dishCount=NA, cellSize=cellCount, dishAreaOccupied=resect)
  }else{
    dishSurfaceArea_cm2 = .readDishSurfaceArea_cm2(flask, mydb)
    dish = .readCellSegmentationsOutput(id= id, from=from, cellLine = parent$cellLine, dishSurfaceArea_cm2 = dishSurfaceArea_cm2, cellCount = cellCount, excludeOption=excludeOption, preprocessing=preprocessing, param=param);
  }
  
  ### Passaging info
  passage = parent$passage
  if(event=="seeding"){
    passage = passage+1
  }
  
  ## User info
  mydb = connect2DB()
  rs = suppressWarnings(dbSendQuery(mydb, "SELECT user()"));
  user=fetch(rs, n=-1)[,1];
  
  ### Check id, passaged_from_id1: is there potential for incorrect assignment between them?
  stmt = "SELECT id, event, passaged_from_id1, correctedCount,passage, date from Passaging";
  rs = suppressWarnings(dbSendQuery(mydb, stmt))
  passaging = fetch(rs, n=-1)
  rownames(passaging) <- passaging$id
  passaging$passage_id <- sapply(passaging$id, .unique_passage_id)
  # x=data.table::transpose(as.data.frame(c(id , event, from, dish$dishCount, passage)))
  # colnames(x) = c("id", "event", "passaged_from_id1", "correctedCount", "passage")
  x=data.table::transpose(as.data.frame(c(id ,parent$cellLine,from,event,as.character(tx),dish$dishCount,dish$dishCount,dish$cellSize, dish$dishAreaOccupied, passage,flask,parent$media,  user,  user)))
  colnames(x) = c("id", "cellLine","passaged_from_id1", "event", "date", "cellCount","correctedCount","cellSize_um2","areaOccupied_um2", "passage", "flask", "media", "owner", "lastModified")
  rownames(x) <- x$id
  x4DB <- x
  x$passage_id <- .unique_passage_id(x$id)
  probable_ancestor <- try(.assign_probable_ancestor(x$id,xi=passaging), silent = T)
  ancestorCheck = T;
  if(class(probable_ancestor)!="try-error" && !isempty(probable_ancestor) ){
    x$probable_ancestor = probable_ancestor
    if(x$passaged_from_id1!=x$probable_ancestor){
      confirmAncestorCorrect = ""
      while(!confirmAncestorCorrect %in% c("yes", "no")){
        confirmAncestorCorrect <- readline(prompt=paste0("Warning encountered while updating database: Was ",x$id," really derived from ",x$passaged_from_id1,"? type yes/no: "))
      }
      if(confirmAncestorCorrect=="no"){
        ancestorCheck=F;
        ## @TODO: this is redundant code. Write short function for this and use it everywhere.
        confirmError = "no"
        while(confirmError!="yes"){
          confirmError <- readline(prompt="No changes are made to the database. Please modify passaged_from_id1, then rerun. Type yes to confirm: ")
        }
      }
    }
  }
  
  ## non-numeric entries formatting:
  ii=which(!names(x) %in% c("cellSize_um2","areaOccupied_um2","correctedCount","cellCount", "passage", "flask", "media"))
  x[ii]=paste0("'",x[ii],"'")
  x4DB <- x[names(x4DB)]
  x4DB[is.na(x4DB)]="NULL"
  
  ## Attempt to update the DB:
  if(ancestorCheck){
    ### Insert
    # stmt = paste0("INSERT INTO Passaging (id, passaged_from_id1, event, date, cellCount, passage, flask, media, owner, lastModified) ",
    # "VALUES ('",id ,"', '",from,"', '",event,"', '",as.character(tx),"', ",dish$dishCount,", ", passage,", ",flask,", ", parent$media, ", '", user, "', '", user, "');")
    stmt = paste0("INSERT INTO Passaging (",paste(names(x4DB), collapse = ", "),") ",
                  "VALUES (",paste(x4DB, collapse = ", "),");")
    rs = try(dbSendQuery(mydb, stmt))
    if(class(rs)!="try-error"){
      stmt = paste0("update Passaging set correctedCount = ",x4DB$correctedCount," where id='",id,"';")
      rs = dbSendQuery(mydb, stmt)
      
      stmt = paste0("update Passaging set areaOccupied_um2 = ",x4DB$areaOccupied_um2," where id='",id,"';")
      rs = dbSendQuery(mydb, stmt)
      stmt = paste0("update Passaging set cellSize_um2 = ",x4DB$cellSize_um2," where id='",id,"';")
      rs = dbSendQuery(mydb, stmt)
    }else{
      confirmError = "no"
      while(confirmError!="yes"){
        confirmError <- readline(prompt="Error encountered while updating database: no changes were made to the database. Please check id is not redundant with existing IDs, then rerun. Type yes to confirm: ")
      }
    }
  }
  
  try(dbClearResult(dbListResults(mydb)[[1]]), silent = T)
  try(dbDisconnect(mydb), silent = T)
  
  return(x4DB)
}

##find the unique string that identifies a passage
.unique_passage_id <- function(i){
  paste(head(unlist(strsplit(i,split="_")),3),collapse="_")
}

## Make suggestions to correct ancestor
.assign_probable_ancestor <- function(i,xi){
  if(xi$event[xi$id==i]=="harvest"){
    return(xi$id[xi$passage_id==xi$passage_id[xi$id==i] & xi$event=="seeding"])
  }
  if(xi$event[xi$id==i]=="seeding"){
    passage_split <- unlist(strsplit(i,split="_"))
    passage_no <- paste0("A",as.numeric(gsub("A","",passage_split[3]))-1)
    passage_id <- paste0(c(passage_split[1:2],passage_no),collapse="_")
    target_passage <- xi[xi$passage_id==passage_id,]
    return(target_passage$id[which.max(as.Date(target_passage$date))])
  }
}


.readCellSegmentationsOutput <- function(id, from, cellLine, dishSurfaceArea_cm2, cellCount, excludeOption, preprocessing=T, param=NULL){
  ## Typical values for dishSurfaceArea_cm2 are: 
  ## a) 75 cm^2 = 10.1 cm x 7.30 cm  
  ## b) 25 cm^2 = 5.08 cm x 5.08 cm
  ## c) well from 96-plate = 0.32 cm^2
  ## CellSegmentations Settings; @TODO: should be set under settings, not here
  UM2CM = 1e-4
  yml = yaml::read_yaml(paste0(system.file(package='cloneid'), '/config/config.yaml'))
  TMP_DIR = normalizePath(paste0(yml$cellSegmentation$tmp,filesep,id));
  CELLSEGMENTATIONS_OUTDIR=paste0(normalizePath(yml$cellSegmentation$output),"/");
  CELLSEGMENTATIONS_INDIR=paste0(normalizePath(yml$cellSegmentation$input),"/");
  # QUPATH_PRJ = "~/Downloads/qproject/project.qpproj"
  # QSCRIPT = "~/Downloads/qpscript/runDetectionROI.groovy"
  CELLPOSE_PARAM=paste0(find.package("cloneid"),filesep,"python/cellPose.param")
  PYTHON_SCRIPTS=list.files(paste0(find.package("cloneid"),filesep,"python"), pattern=".py", full.names = T)
  CELLPOSE_SCRIPT=grep("GetCount_cellPose.py",PYTHON_SCRIPTS, value = T)
  PREPROCESS_SCRIPT=grep("preprocessing.py",PYTHON_SCRIPTS, value = T)
  TISSUESEG_SCRIPT=grep("tissue_seg.py",PYTHON_SCRIPTS, value = T)
  QCSTATS_SCRIPT=grep("QC_Statistics.py",PYTHON_SCRIPTS, value = T)
  suppressWarnings(dir.create(paste0(CELLSEGMENTATIONS_OUTDIR,"DetectionResults")))
  suppressWarnings(dir.create(paste0(CELLSEGMENTATIONS_OUTDIR,"Annotations"))) 
  suppressWarnings(dir.create(paste0(CELLSEGMENTATIONS_OUTDIR,"Images"))); 
  suppressWarnings(dir.create(paste0(CELLSEGMENTATIONS_OUTDIR,"Confluency"))); 
  # suppressWarnings(dir.create("~/Downloads/qpscript"))
  # suppressWarnings(dir.create(fileparts(QUPATH_PRJ)$pathstr))
  # qpversion = list.files("/Applications", pattern = "QuPath")
  # qpversion = gsub(".app","", gsub("QuPath","",qpversion))
  # qpversion = qpversion[length(qpversion)]
  
  ## Load environment and source python scripts
  LOADEDENV='cellpose' %in% conda_list()$name
  if(LOADEDENV){
    use_condaenv("cellpose")
    # py_config()
    print('Cellpose environment loaded')
    # use_condaenv("cellpose", required = TRUE)
    sapply(PYTHON_SCRIPTS, source_python)
  }
  
  ## Copy raw images to temporary directory:
  unlink(TMP_DIR,recursive=T)
  dir.create(TMP_DIR, recursive = T)
  f_i = list.files(CELLSEGMENTATIONS_INDIR, pattern = paste0("^",id,"_"), full.names = T)
  f_i = grep("x_ph_",f_i,value=T)
  f_i = grep(".tif$",f_i,value=T)
  file.copy(f_i, TMP_DIR)
  ## Delete output files from prior runs:
  for(subfolder in c("Annotations","Images","DetectionResults","Confluency")){
    f = list.files(paste0(CELLSEGMENTATIONS_OUTDIR,subfolder), pattern = paste0(id,"_"), full.names = T)
    f = grep("x_ph_",f,value=T)
    file.remove(f)
  }
  
  ## Preprocessing
  if(preprocessing){
    for(x in list.files(TMP_DIR, pattern = ".tif", full.names = T)){
      # cmd = paste("python3",PREPROCESS_SCRIPT, x, cellLine)
      # system(cmd)
      print(paste("Using", PREPROCESS_SCRIPT))
      source_python(PREPROCESS_SCRIPT)
      ApplyGammaCorrection(x, cellLine)
    }
  }
  
  ## Cell segmentation
  ## Call CellPose for images inside temp dir 
  # virtualenv_list()
  source_python(CELLPOSE_SCRIPT)
  ## cellPose parameters:
  if(is.null(param)){
    cpp=read.table(CELLPOSE_PARAM,header=T,row.names = 1) 
    ##Let's zoom in on just a subset of entries of cpp, based on the "cellLine" param
    mydb = connect2DB()
    stmt = paste0("select id, cellLine from Passaging where id in (\'",paste(setdiff(rownames(cpp),"default"),collapse = "', '"),"\') ")
    rs = dbSendQuery(mydb, stmt)
    cli = fetch(rs, n=-1)
    dbClearResult(dbListResults(mydb)[[1]])
    dbDisconnect(mydb)
    cli=rbind(cli,c("default","default"))
    rownames(cli)=cli$id
    cpp$cellLine=cli[rownames(cpp),"cellLine"]
    cpp=cpp[cpp$cellLine %in% c(cellLine,"default"),,drop=F]
    ## Now iterate through entries of cpp that we have left:
    for(cl in setdiff(rownames(cpp),"default")){
      tmp=cloneid::findAllDescendandsOf(id=cl,verbose = F); 
      if(from %in% tmp$id){
        param=as.list(cpp[cl,])
        ##@TODO: this will pick the first lineage that fits. If there are multiple lineages that fit, the subsequent ones will be ignored
        break; 
      }
    }
    if(is.null(param)){
      param=as.list(cpp["default",])
    }
  }
  param$cellposeModel=paste0(find.package("cloneid"),filesep,"python",filesep, param$cellposeModel)
  print(param)
  run(TMP_DIR,normalizePath(param$cellposeModel),TMP_DIR,".tif", as.character(param$diameter), as.character(param$flow_threshold), as.character(param$cellprob_threshold))
  
  ## Tissue segmentation
  for(x in f_i){
    imgPath=paste0(TMP_DIR,filesep,fileparts(x)$name,".tif")
    source_python(TISSUESEG_SCRIPT)
    get_mask(imgPath,paste0(TMP_DIR,filesep,"Confluency"),toupper(cellLine),"False")
  }
  
  
  ## Add QC statistics
  if(LOADEDENV){
    source_python(QCSTATS_SCRIPT)
    QC_Statistics(TMP_DIR,paste0(TMP_DIR,filesep,"cellpose_count"),'.tif')
  }
  ## Move files from tempDir to destination:
  cellPoseOut_csv = list.files(TMP_DIR, recursive = T, pattern = ".csv",full.names = T)
  sapply(grep("pred",cellPoseOut_csv,value = T), function(x) file.copy(x, paste0(CELLSEGMENTATIONS_OUTDIR,"DetectionResults") ))
  sapply(grep("cellpose_count",cellPoseOut_csv,value = T), function(x) file.copy(x, paste0(CELLSEGMENTATIONS_OUTDIR,"Annotations") ))
  sapply(grep("Confluency",cellPoseOut_csv,value = T), function(x) file.copy(x, paste0(CELLSEGMENTATIONS_OUTDIR,"Confluency") ))
  cellPoseOut_img = list.files(TMP_DIR, recursive = T, pattern = "overlay.",full.names = T)
  tissuesegOut_img = list.files(TMP_DIR, recursive = T, pattern = "mask.",full.names = T)
  sapply(cellPoseOut_img, function(x) file.copy(x, paste0(CELLSEGMENTATIONS_OUTDIR,"Images") ))
  sapply(tissuesegOut_img, function(x) file.copy(x, paste0(CELLSEGMENTATIONS_OUTDIR,"Confluency") ))
  
  ## Wait and look for imaging analysis output
  print(paste0("Waiting for ",id," to appear under ",CELLSEGMENTATIONS_OUTDIR," ..."), quote = F)
  f = c()
  while(length(f)<length(f_i)){
    Sys.sleep(3)
    f = list.files(paste0(CELLSEGMENTATIONS_OUTDIR,"DetectionResults"), pattern = paste0(id,"_"), full.names = T)
    f = grep("x_ph_",f,value=T)
  }
  f_a = list.files(paste0(CELLSEGMENTATIONS_OUTDIR,"Annotations"), pattern = paste0(id,"_"), full.names = T)
  f_o = list.files(paste0(CELLSEGMENTATIONS_OUTDIR,"Images"), pattern = paste0(id,"_"), full.names = T)
  f_c = list.files(paste0(CELLSEGMENTATIONS_OUTDIR,"Confluency"), pattern = ".csv", full.names = T)
  f_c = grep(paste0(id,"_"), f_c, value=T)
  print(paste0("Output found for ",fileparts(f[1])$name," and ",(length(f)-1)," other image files."), quote = F)
  
  
  ## Read automated image analysis output
  cellCounts = matrix(NA,length(f),4);
  colnames(cellCounts) = c("areaCount","area_cm2","dishAreaOccupied", "cellSize_um2")
  rownames(cellCounts) = sapply(f, function(x) fileparts(x)$name)
  # pdf(OUTSEGF)
  for(i in 1:length(f)){
    dm = read.table(f[i],sep="\t", check.names = F, stringsAsFactors = F, header = T)
    colnames(dm)[grep("^Area",colnames(dm))]="Cell: Area"; ## Replace cellPose column name -- @TODO: saeed fix directly in cellposeScript
    anno = read.table(f_a[i],sep="\t", check.names = T, stringsAsFactors = F, header = T)
    conf = read.csv(f_c[i])
    colnames(anno) = tolower(colnames(anno))
    areaCount = nrow(dm)
    # areaCount = sum(conf$`Area.in.um`)/median(dm$`Cell: Area`)
    area_cm2 = anno[1,grep("^area.",colnames(anno))]*UM2CM^2
    cellCounts[fileparts(f[i])$name,] = c(areaCount, area_cm2, sum(conf$`Area.in.um`), quantile(dm$`Cell: Area`, 0.9, na.rm=T))
    # ## Visualize
    # ## @TODO: Delete
    # if(!file.exists(f_o[i])){
    #   la=raster::raster(f_i[i])
    #   ROI <- as(raster::extent(100, 1900, la@extent@ymax - 1200, la@extent@ymax - 100), 'SpatialPolygons')
    #   la_ <- raster::crop(la, ROI)
    #   raster::plot(la_, ann=FALSE,axes=FALSE, useRaster=T,legend=F)
    #   mtext(fileparts(f_i[i])$name, cex=1)
    #   points(dm$`Centroid X µm`,la@extent@ymax - dm$`Centroid Y µm`, col="black", pch=20, cex=0.3)
    # }else{
    #   img <- magick::image_read(f_o[i])
    #   plot(img)
    #   mtext(fileparts(f_o[i])$name, cex=1)
    # }
  }
  # dev.off()
  # file.copy(OUTSEGF, paste0(TMP_DIR,filesep) )
  
  ## Predict cell count error
  print("Predicting cell count error...",quote=F)
  for(i in 1:length(f_a)){
    anno = read.table(f_a[i],sep="\t", check.names = T, stringsAsFactors = F, header = T)
    ## No cells detected
    if(is.null(anno$Num.Detections)){
      anno$Num.Detections=0;
    }
    ## use CL-specific model if it exists, otherwise use general model
    data(list="General_logErrorModel")
    ## Loads cell line specific linear model "linM" -- overrides general model loaded above if cell line specific model exists
    data(list=paste0(cellLine,"_logErrorModel"))
    if(!any(c("Variance.of.Laplician","fft") %in% colnames(anno))){
      warning("No features for error prediction available", immediate. = T)
      excludeOption=T
      break;
    }
    anno$log.error = predict(linM, newdata=anno)
    if(anno$log.error>linM$MAXERROR){
      warning("Low image quality predicted for at least one image")
      excludeOption=T
      break;
    }else{
      print(paste("Cell count error predicted as negligible for",f_a[i]),quote=F)
    }
  }
  
  ## Provide option to exclude subset of images
  if(excludeOption){
    toExclude <- readline(prompt="Exclude any images (bl, br, tl, tr)?")
    if(nchar(toExclude)>0){
      toExclude = sapply(strsplit(toExclude,",")[[1]],trimws)
      toExclude = c(paste0(as.character(toExclude),".tif"), paste0(as.character(toExclude),"$"))
      ii = sapply(toExclude, function(x) grep(x, rownames(cellCounts)))
      ii = unlist(ii[sapply(ii,length)>0])
      if(!isempty(ii)){
        print(paste("Excluding",rownames(cellCounts)[ii],"from analysis."), quote = F)
        cellCounts= cellCounts[-ii,, drop=F]
      }
      if(length(ii)==length(f)){
        stop("At least one valid image needs to be left. Aborting")
      }
    }
  }
  
  
  ## Calculate cell count per dish
  area2dish = dishSurfaceArea_cm2 / sum(cellCounts[,"area_cm2"])
  dishCount = round(sum(cellCounts[,"areaCount"]) * area2dish)
  dishConfluency = sum(cellCounts[,"dishAreaOccupied"]) * area2dish
  cellSize = median(cellCounts[,"cellSize_um2"],na.rm=T)
  print(paste("Estimated number of cells in entire flask at",dishCount), quote = F)
  
  if(!is.na(cellCount) && (dishCount/cellCount > 2 || dishCount/cellCount <0.5)){
    warning(paste0("Automated image analysis deviates from input cell count by more than a factor of 2. CellCount set to the former (",dishCount," cells)"))
  }
  return(list(dishCount=dishCount,dishAreaOccupied=dishConfluency, cellSize=cellSize))
}




.QuPathScript <- function(qpdir, cellLine){
  # Standard pipeline:
  runPlugin = "runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{\"detectionImageBrightfield\": \"Hematoxylin OD\",  \"requestedPixelSizeMicrons\": 1.0,  \"backgroundRadiusMicrons\": 15.0,  \"medianRadiusMicrons\": 0.0,  \"sigmaMicrons\": 1.5,  \"minAreaMicrons\": 2.0,  \"maxAreaMicrons\": 1000.0,  \"threshold\": 0.1,  \"maxBackground\": 2.9,  \"watershedPostProcess\": false,  \"cellExpansionMicrons\": 2.5,  \"includeNuclei\": false,  \"smoothBoundaries\": true,  \"makeMeasurements\": true}');"
  # # NCI-N87 pipeline:
  if(cellLine=="NCI-N87"){
    # runPlugin = "runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{\"detectionImageBrightfield\": \"Hematoxylin OD\",  \"requestedPixelSizeMicrons\": 0.5,  \"backgroundRadiusMicrons\": 8.0,  \"medianRadiusMicrons\": 0.0,  \"sigmaMicrons\": 1.5,  \"minAreaMicrons\": 40.0,  \"maxAreaMicrons\": 400.0,  \"threshold\": 0.09,  \"maxBackground\": 3.0,  \"watershedPostProcess\": false,  \"cellExpansionMicrons\": 5.0,  \"includeNuclei\": false,  \"smoothBoundaries\": true,  \"makeMeasurements\": true}');"
    runPlugin = "runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{\"detectionImageBrightfield\": \"Hematoxylin OD\",  \"requestedPixelSizeMicrons\": 0.461,  \"backgroundRadiusMicrons\": 12.0,  \"medianRadiusMicrons\": 0.0,  \"sigmaMicrons\": 1,  \"minAreaMicrons\": 15,  \"maxAreaMicrons\": 200.0,  \"threshold\": 0.2,  \"maxBackground\": 3.0,  \"watershedPostProcess\": true,  \"cellExpansionMicrons\": 3.0,  \"includeNuclei\": false,  \"smoothBoundaries\": true,  \"makeMeasurements\": true}');"
  }else if(cellLine=="HGC-27" || cellLine=="SUM-159"){
    runPlugin = "runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{\"detectionImageBrightfield\": \"Hematoxylin OD\",  \"requestedPixelSizeMicrons\": 0.5,  \"backgroundRadiusMicrons\": 8.0,  \"medianRadiusMicrons\": 0.0,  \"sigmaMicrons\": 1.5,  \"minAreaMicrons\": 90.0,  \"maxAreaMicrons\": 1200.0,  \"threshold\": 0.1,  \"maxBackground\": 2.0,  \"watershedPostProcess\": false,  \"cellExpansionMicrons\": 5.0,  \"includeNuclei\": false,  \"smoothBoundaries\": true,  \"makeMeasurements\": true}');"
  }else if (cellLine=="SNU-16"){
    runPlugin = "runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{\"detectionImageBrightfield\": \"Hematoxylin OD\",  \"requestedPixelSizeMicrons\": 0.5,  \"backgroundRadiusMicrons\": 8.0,  \"medianRadiusMicrons\": 0.0,  \"sigmaMicrons\": 3.5,  \"minAreaMicrons\": 40.0,  \"maxAreaMicrons\": 800.0,  \"threshold\": 0.1,  \"maxBackground\": 2.0,  \"watershedPostProcess\": false,  \"cellExpansionMicrons\": 5.0,  \"includeNuclei\": false,  \"smoothBoundaries\": true,  \"makeMeasurements\": true}');"
  }else  if(cellLine=="NUGC-4"){
    runPlugin = "runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{\"detectionImageBrightfield\": \"Hematoxylin OD\",  \"requestedPixelSizeMicrons\": 0.922,  \"backgroundRadiusMicrons\": 8.0,  \"medianRadiusMicrons\": 2.0,  \"sigmaMicrons\": 1.5,  \"minAreaMicrons\": 10.0,  \"maxAreaMicrons\": 200.0,  \"threshold\": 0.1,  \"maxBackground\": 2.9,  \"watershedPostProcess\": true,  \"cellExpansionMicrons\": 2.5,  \"includeNuclei\": false,  \"smoothBoundaries\": true,  \"makeMeasurements\": true}');"
  }else if(cellLine=="KATOIII"){
    runPlugin = "runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{\"detectionImageBrightfield\": \"Hematoxylin OD\",  \"requestedPixelSizeMicrons\": 0.5,  \"backgroundRadiusMicrons\": 8.0,  \"medianRadiusMicrons\": 0.0,  \"sigmaMicrons\": 1.5,  \"minAreaMicrons\": 40.0,  \"maxAreaMicrons\": 1200.0,  \"threshold\": 0.09,  \"maxBackground\": 3.0,  \"watershedPostProcess\": true,  \"cellExpansionMicrons\": 5.0,  \"includeNuclei\": false,  \"smoothBoundaries\": true,  \"makeMeasurements\": true}');"
  }
  qpdir = normalizePath(qpdir)
  paste(" import static qupath.lib.gui.scripting.QPEx.*"
        ," import qupath.lib.gui.tools.MeasurementExporter"
        ," import qupath.lib.objects.PathCellObject"
        ," import java.awt.Color"
        ," import java.awt.*"
        ," import qupath.lib.objects.PathDetectionObject"
        ," import qupath.lib.gui.viewer.OverlayOptions"
        ," import qupath.lib.gui.viewer.overlays.HierarchyOverlay"
        ," import qupath.lib.gui.images.servers.RenderedImageServer"
        ," "
        ," import qupath.lib.gui.viewer.overlays.BufferedImageOverlay"
        ," import qupath.opencv.tools.OpenCVTools"
        ," "
        ," "
        ," //  User enter these information for every project."
        ," //*************************************************"
        ," def PixelWidth_new = 1.000;"
        ," def PixelHeight_new = 1.000;"
        ," def x_left = 100;"
        ," def y_left = 100;"
        ," def w_ROI =  1900;"
        ," def h_ROI = 1100;"
        ," //*************************************************"
        ," "
        ," "
        ," def project = getProject();"
        ," def entry = getProjectEntry();"
        ," def imageData = entry.readImageData();"
        ," def CurrentImageData = getCurrentImageData();"
        ," def hierarchy = imageData.getHierarchy();"
        ," def annotations = hierarchy.getAnnotationObjects();"
        ," "
        ," def server = CurrentImageData.getServer();"
        ," def path = server.getPath();"
        ," def cal = server.getPixelCalibration();"
        ," double pixelWidth = cal.getPixelWidthMicrons();"
        ," double pixelHeight = cal.getPixelHeightMicrons();"
        ," "
        ," "
        ," def filename = entry.getImageName() + '.csv'"
        , "// @TODO: read this info directly from .tif metadata"
        ," if (filename.contains('_20x_')){"
        ,"   print('20x data');"
        ,"   PixelWidth_new = 200/433.77;"
        ,"   print(PixelWidth_new);"
        ,"   setPixelSizeMicrons(PixelWidth_new, PixelWidth_new);"
        ," }else if (filename.contains('_10x_')){"
        ,"   print('10x data');"
        ,"   PixelWidth_new = 400/433.77;"
        ,"   print(PixelWidth_new);"
        ,"   setPixelSizeMicrons(PixelWidth_new, PixelWidth_new);"
        ," }else if (filename.contains('_40x_')){"
        ,"   print('40x data');"
        ,"   PixelWidth_new = 100/433.77;"
        ,"   print(PixelWidth_new);"
        ,"   setPixelSizeMicrons(PixelWidth_new, PixelWidth_new);"
        ," }"
        ," "
        ," setImageType('BRIGHTFIELD_H_E');"
        ," setColorDeconvolutionStains('{\"Name\" : \"H&E default\", \"Stain 1\" : \"Hematoxylin\", \"Values 1\" : \"0.65111 0.70119 0.29049 \", \"Stain 2\" : \"Eosin\", \"Values 2\" : \"0.2159 0.8012 0.5581 \", \"Background\" : \" 255 255 255 \"}');"
        ," def plane = ImagePlane.getPlane(0,0);"
        ," def rectangle = ROIs.createRectangleROI(x_left,y_left,w_ROI,h_ROI,plane);"
        ," def rectangleAnnotation = PathObjects.createAnnotationObject(rectangle);"
        ," QPEx.addObjects(rectangleAnnotation);"
        ," println \"Success\";"
        ," //createSelectAllObject(true);"
        ," selectAnnotations();"
        , runPlugin
        ," "
        ," selectDetections()"
        , paste0("def pathDetection = buildFilePath('",qpdir,"/pred');")
        , paste0("def pathAnnotation = buildFilePath('",qpdir,"/cellpose_count')")
        ," mkdirs(pathDetection);"
        ," mkdirs(pathAnnotation);"
        ," def (basename,ext) = filename.tokenize('.');"
        ," pathDetection = buildFilePath(pathDetection, basename+'.csv');"
        ," pathAnnotation = buildFilePath(pathAnnotation, basename+'.csv');"
        ," saveDetectionMeasurements(pathDetection);"
        ," saveAnnotationMeasurements(pathAnnotation)"
        ," "
        ," // Saving Image to file "
        , paste0("def vis_path = buildFilePath('",qpdir,"/vis');")
        ," mkdirs(vis_path);"
        ," vis_path_instance = buildFilePath(vis_path,basename+'_overlay.tif');"
        ," "
        ," //*********************** Save Labeled Image ****************************"
        ," def downsample = 1"
        ," def viewer = getCurrentViewer()"
        ," def labelServer_rendered = new RenderedImageServer.Builder(CurrentImageData)"
        ,"    .downsamples(downsample)"
        ,"    .layers(new HierarchyOverlay(null, new OverlayOptions(), imageData))"
        ,"    .build()"
        ," writeImage(labelServer_rendered, vis_path_instance)"
        , " "
        ," //------------------------- Save Masks   ----------------------------------"
        , "def SaveBinaryMasks4(server,downsample,basename,Path2SaveResults){" 
        ," int w = (server.getWidth() / downsample) as int" 
        ," int h = (server.getHeight() / downsample) as int" 
        ," def img = new BufferedImage(w, h, BufferedImage.TYPE_BYTE_GRAY)" 
        ," def g2d = img.createGraphics()" 
        ," g2d.scale(1.0/downsample, 1.0/downsample)" 
        ," g2d.setColor(Color.WHITE)" 
        ," for (detection in getDetectionObjects()) {" 
        ,"  roi = detection.getROI()" 
        ,"  def shape = roi.getShape()" 
        ,"  g2d.setPaint(Color.white);" 
        ,"  g2d.fill(shape)" 
        ,"  g2d.setStroke(new BasicStroke(4)); // 8-pixel wide pen" 
        ,"  g2d.setPaint(Color.black);" 
        ,"  g2d.draw(shape)" 
        ," }"   
        ,"   g2d.dispose()"
        ," "  
        ,"   // Write the image" 
        ," def masks_path = buildFilePath(Path2SaveResults,'masks');" 
        ," mkdirs(masks_path);" 
        ," mask_path_instance = buildFilePath(masks_path,basename+'.tif');" 
        ," writeImage(img, mask_path_instance)" 
        ,"}"
        , paste0("   SaveBinaryMasks4(server,downsample,basename,'",qpdir,"');") 
        ," "
        ," //*********************** Save Labeled Image Updated Beacuse of the error Noemi Encountered with viewer *********"
        ," //def downsample = 1"
        ," //def labelServer = new LabeledImageServer.Builder(CurrentImageData)"
        ," //  .backgroundLabel(0, ColorTools.BLACK) // Specify background label (usually 0 or 255)"
        ," //  .downsample(downsample)    // Choose server resolution; this should match the resolution at which tiles are exported"
        ," //  .useCells()"
        ," //  .useInstanceLabels()"
        ," //  .setBoundaryLabel('Ignore', 1) "
        ," //  .multichannelOutput(false) // If true, each label refers to the channel of a multichannel binary image (required for multiclass probability)"
        ," //  .build()", sep="\n" )
}



.SaveProject <- function(QUPATH_PRJ, imgFiles){
  prj = paste("{",
              "  \"version\": \"0.2.3\",",
              "  \"createTimestamp\": 1606857053400,",
              "  \"modifyTimestamp\": 1606857053400,",
              paste0("  \"uri\": \"file:", normalizePath(QUPATH_PRJ), "\","),
              paste0("  \"lastID\": ", length(imgFiles), ","),
              "  \"images\": [", sep="\n" )
  for(i in 1:length(imgFiles)){
    imgFile = normalizePath(imgFiles[i])
    prj = paste(prj,
                "    {",
                "      \"serverBuilder\": {",
                "        \"builderType\": \"uri\",",
                "        \"providerClassName\": \"qupath.lib.images.servers.bioformats.BioFormatsServerBuilder\",",
                paste0("        \"uri\": \"file:",imgFile,"\","),
                "        \"args\": [",
                "          \"--series\",",
                "          \"0\"",
                "        ],",
                "        \"metadata\": {",
                paste0("          \"name\": \"",fileparts(imgFile)$name,fileparts(imgFile)$ext,"\","),
                "          \"width\": 2048,",
                "          \"height\": 1536,",
                "          \"sizeZ\": 1,",
                "          \"sizeT\": 1,",
                "          \"channelType\": \"DEFAULT\",",
                "          \"isRGB\": true,",
                "          \"pixelType\": \"UINT8\",",
                "          \"levels\": [",
                "            {",
                "              \"downsample\": 1.0,",
                "              \"width\": 2048,",
                "              \"height\": 1536",
                "            }",
                "          ],",
                "          \"channels\": [",
                "            {",
                "              \"name\": \"Red\",",
                "              \"color\": -65536",
                "            },",
                "            {",
                "              \"name\": \"Green\",",
                "              \"color\": -16711936",
                "            },",
                "            {",
                "              \"name\": \"Blue\",",
                "              \"color\": -16776961",
                "            }",
                "          ],",
                "          \"pixelCalibration\": {",
                "            \"pixelWidth\": {",
                "              \"value\": 1.0,",
                "              \"unit\": \"µm\"",
                "            },",
                "            \"pixelHeight\": {",
                "              \"value\": 1.0,",
                "              \"unit\": \"µm\"",
                "            },",
                "            \"zSpacing\": {",
                "              \"value\": 1.0,",
                "              \"unit\": \"z-slice\"",
                "            },",
                "            \"timeUnit\": \"SECONDS\",",
                "            \"timepoints\": []",
                "          },",
                "          \"preferredTileWidth\": 2048,",
                "          \"preferredTileHeight\": 170",
                "        }",
                "      },",
                paste0("      \"entryID\": ",i,","),
                paste0("      \"randomizedName\": \"d",i,"f15668-2b0e-",i,"f",i,"e-b953-9794d9047a",i,"b\","),
                paste0("      \"imageName\": \"",fileparts(imgFile)$name,fileparts(imgFile)$ext,"\","),
                "      \"metadata\": {}",
                "    },", sep="\n" );
  }
  prj = gsub(",$","",prj)
  prj = paste(prj,
              "  ]",
              "}", sep="\n" )
  return(prj)
}


GenomePerspectiveView_Bulk<-function(id){
  out=findAllDescendandsOf(id, recursive = T)
  mydb = cloneid::connect2DB()
  stmt = paste0("select distinct origin from Perspective where whichPerspective='GenomePerspective' and origin IN ('",paste(unique(out$id), collapse="','"),"')")
  rs = suppressWarnings(dbSendQuery(mydb, stmt))
  origin=fetch(rs, n=-1)[,"origin"]
  
  p=sapply(origin, function(x) getSubProfiles(cloneID_or_sampleName = x, whichP = "GenomePerspective"))
  p=do.call(cbind, p)
  gplots::heatmap.2(t(p), trace = "n")
}
