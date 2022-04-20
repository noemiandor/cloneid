seed <- function(id, from, cellCount, flask, tx = Sys.time(), media=NULL, excludeOption=F){ 
  .seed_or_harvest(event = "seeding", id=id, from = from, cellCount = cellCount, tx = tx, flask = flask, media = media, excludeOption=excludeOption)
}


harvest <- function(id, from, cellCount, tx = Sys.time(), media=NULL, excludeOption=F){
  .seed_or_harvest(event = "harvest", id=id, from=from, cellCount = cellCount, tx = tx, flask = NULL, media = media, excludeOption=excludeOption)
}


init <- function(id, cellLine, cellCount, tx = Sys.time(), media=NULL, flask=NULL){
  mydb = connect2DB()
  
  dishCount = cellCount;
  if(!is.null(flask)){
    dishSurfaceArea_cm2 = .readDishSurfaceArea_cm2(flask, mydb)
    dishCount = .readCellSegmentationsOutput(id= id, cellLine = cellLine, dishSurfaceArea_cm2 = dishSurfaceArea_cm2, cellCount = cellCount);
  }
  if(is.null(media)){
    media = "NULL"
  }
  if(is.null(flask)){
    flask = "NULL"
  }
  stmt = paste0("INSERT INTO Passaging (id, cellLine, event, date, cellCount, passage, flask, media) ",
                "VALUES ('",id ,"', '",cellLine,"', 'harvest', '",tx,"', ",dishCount,", ", 1,", ",flask,", ", media, ");")
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
  stmt = paste0("UPDATE Passaging SET ",names(priorfeedings)[nextI]," = '",tx,"' where id = '",id ,"'") 
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

getPedigreeTree <- function(cellLine= cellLine, id = NULL, cex = 0.5){
  library(RMySQL)
  library(ape)
  
  mydb = connect2DB()
  if(is.null(id)){
    stmt = paste0("select * from Passaging where cellLine = '",cellLine,"'");
    rs = suppressWarnings(dbSendQuery(mydb, stmt))
    kids = fetch(rs, n=-1)
  }else{
    kids = findAllDescendandsOf(id, mydb = mydb)
  }
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
  plot(tr, underscore = T, cex=cex, tip.color = col[kids[tr$tip.label,]$event])
  legend("topright",names(col),fill=col, bty="n")
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
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
  mydb = connect2DB()
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

plotLiquidNitrogenBox <- function(rack, row){
  library(RMySQL)
  mydb = connect2DB()
  cmd=paste0("select * from LiquidNitrogen where ",
             "Rack = '",rack,"' AND ",
             "Row = '",row,"'");
  print(cmd)
  rs = dbSendQuery(mydb, cmd);
  kids = fetch(rs, n=-1)
  kids$id[is.na(kids$id)] = "NA"
  
  ## Visualize
  rc = apply(kids, 2, unique)
  par(mfrow=c(2,2), mai=c(0,0.5,0.5,0))
  plot(c(1,length(rc$BoxColumn)),c(1,length(rc$BoxRow)), col="white", yaxt="n", xaxt="n", xlab="",ylab="", main=paste("Rack",rack,"; Row",row),ylim = rev(range(c(1,length(rc$BoxRow)))) )
  axis(1, at=1:length(rc$BoxColumn), labels=rc$BoxColumn, las=1)
  axis(2, at=1:length(rc$BoxRow), labels=rc$BoxRow, las=2)
  cols = gray.colors(length(rc$id)*1.2)[1:length(rc$id)]
  names(cols) = unique(rc$id)
  cols["NA"] = "white"
  for(i in 1:nrow(kids)){
    points(match(kids$BoxColumn[i], rc$BoxColumn), match(kids$BoxRow[i], rc$BoxRow), col=cols[kids$id[i]], pch=20, cex=4)
  }
  
  plot(1,1,axes=F, col="white")
  legend("topleft", names(cols), fill=cols)
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
}


.seed_or_harvest <- function(event, id, from, cellCount, tx, flask, media, excludeOption){
  library(RMySQL)
  library(matlab)
  
  EVENTTYPES = c("seeding","harvest")
  otherevent = EVENTTYPES[EVENTTYPES!=event]
  
  mydb = connect2DB()
  
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
  if(event=="seeding" && !is.na(kids$cellCount) && !is.na(cellCount) && cellCount>kids$cellCount){
    print("You cannot seed more than is available from harvest!", quote = F)
    return()
  }
  if(is.na(kids$media) || !is.null(media)){
    if(is.null(media)){
      print("Please enter media information", quote = F)
      return()
    }else{
      kids$media = media
    }
  }else{
    warning(paste("Copying media information from parent: media set to",kids$media))
  }
  ## TODO: What if from is too far in the past
  
  ## flask cannot have changed if this is a harvest event: 
  if(event=="harvest"){
    flask = kids$flask
  }
  
  dishSurfaceArea_cm2 = .readDishSurfaceArea_cm2(flask, mydb)
  
  dishCount = .readCellSegmentationsOutput(id= id, cellLine = kids$cellLine, dishSurfaceArea_cm2 = dishSurfaceArea_cm2, cellCount = cellCount, excludeOption=excludeOption);
  
  ### Insert
  passage = kids$passage
  if(event=="seeding"){
    passage = passage+1
  }
  ## @TODO: remove
  # stmt = paste0("update Passaging set cellCount = ",dishCount," where id='",id,"';")
  stmt = paste0("INSERT INTO Passaging (id, passaged_from_id1, event, date, cellCount, passage, flask, media) ",
                "VALUES ('",id ,"', '",from,"', '",event,"', '",tx,"', ",dishCount,", ", passage,", ",flask,", ", kids$media, ");")
  rs = dbSendQuery(mydb, stmt)
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
}


.readCellSegmentationsOutput <- function(id, cellLine, dishSurfaceArea_cm2, cellCount, excludeOption){
  ## Typical values for dishSurfaceArea_cm2 are: 
  ## a) 75 cm^2 = 10.1 cm x 7.30 cm  
  ## b) 25 cm^2 = 5.08 cm x 5.08 cm
  ## c) well from 96-plate = 0.32 cm^2
  ## CellSegmentations Settings; @TODO: should be set under settings, not here
  UM2CM = 1e-4
  TMP_DIR = normalizePath("~/Downloads/tmp");
  CELLSEGMENTATIONS_DIR="~/CellSegmentations/output/"; 
  QUPATH_PRJ = "~/Downloads/qproject/project.qpproj"
  QSCRIPT = "~/Downloads/qpscript/runDetectionROI.groovy"
  CELLPOSE_MODEL=list.files(paste0(find.package("cloneid"),filesep,"python"),pattern = "cellpose_residual", full.names=T)
  CELLPOSE_SCRIPT=paste0(find.package("cloneid"),filesep,"python/GetCount_cellPose.py")
  QCSTATS_SCRIPT=paste0(find.package("cloneid"),filesep,"python/QC_Statistics.py")
  # OUTSEGF=paste0(CELLSEGMENTATIONS_DIR,"Images",filesep,id,"_segmentations.pdf")
  suppressWarnings(dir.create(paste0(CELLSEGMENTATIONS_DIR,"DetectionResults")))
  suppressWarnings(dir.create(paste0(CELLSEGMENTATIONS_DIR,"Annotations"))) 
  suppressWarnings(dir.create(paste0(CELLSEGMENTATIONS_DIR,"Images"))); 
  suppressWarnings(dir.create("~/Downloads/qpscript"))
  suppressWarnings(dir.create(fileparts(QUPATH_PRJ)$pathstr))
  qpversion = list.files("/Applications", pattern = "QuPath")
  qpversion = gsub(".app","", gsub("QuPath","",qpversion))
  qpversion = qpversion[length(qpversion)]
  LOADEDENV='cellpose' %in% conda_list()$name
  if(LOADEDENV){
    use_condaenv("cellpose")
  }
  
  ## Copy raw images to temporary directory:
  unlink(TMP_DIR,recursive=T)
  dir.create(TMP_DIR)
  f_i = list.files("~/CellSegmentations", pattern = paste0("^",id,"_"), full.names = T)
  f_i = grep("x_ph_",f_i,value=T)
  f_i = grep(".tif$",f_i,value=T)
  file.copy(f_i, TMP_DIR)
  ## Delete output files from prior runs:
  for(subfolder in c("Annotations","Images","DetectionResults")){
    f = list.files(paste0(CELLSEGMENTATIONS_DIR,subfolder), pattern = paste0(id,"_"), full.names = T)
    f = grep("x_ph_",f,value=T)
    file.remove(f)
  }
  
  ## @TODO: use cellpose for all cell lines 
  if(cellLine!="HGC-27"){
    ## Call QuPath for images inside temp dir:
    write(.QuPathScript(qpdir = TMP_DIR, cellLine = cellLine), file=QSCRIPT)
    write(.SaveProject(QUPATH_PRJ, paste0(TMP_DIR,filesep,sapply(f_i, function(x) fileparts(x)$name),".tif")), file=QUPATH_PRJ)
    cmd = paste0("/Applications/QuPath",qpversion,".app/Contents/MacOS/QuPath",qpversion," script ", QSCRIPT, " -p ", QUPATH_PRJ)
    print(cmd, quote = F)
    system(cmd)
  }else{
    ## Call CellPose for images inside temp dir 
    # virtualenv_list()
    source_python(CELLPOSE_SCRIPT)
    run(TMP_DIR,normalizePath(CELLPOSE_MODEL),TMP_DIR,".tif")
  }
  
  ## Add QC statistics
  if(LOADEDENV){
    source_python(QCSTATS_SCRIPT)
    QC_Statistics(TMP_DIR,paste0(TMP_DIR,filesep,"cellpose_count"),'.tif')
  }
  ## Move files from tempDir to destination:
  cellPoseOut_csv = list.files(TMP_DIR, recursive = T, pattern = ".csv",full.names = T)
  sapply(grep("pred",cellPoseOut_csv,value = T), function(x) file.copy(x, paste0(CELLSEGMENTATIONS_DIR,"DetectionResults") ))
  sapply(grep("cellpose_count",cellPoseOut_csv,value = T), function(x) file.copy(x, paste0(CELLSEGMENTATIONS_DIR,"Annotations") ))
  cellPoseOut_img = list.files(TMP_DIR, recursive = T, pattern = "overlay.",full.names = T)
  sapply(cellPoseOut_img, function(x) file.copy(x, paste0(CELLSEGMENTATIONS_DIR,"Images") ))
  
  ## Wait and look for imaging analysis output
  print(paste0("Waiting for ",id," to appear under ",CELLSEGMENTATIONS_DIR," ..."), quote = F)
  f = c()
  while(length(f)<length(f_i)){
    Sys.sleep(3)
    f = list.files(paste0(CELLSEGMENTATIONS_DIR,"DetectionResults"), pattern = paste0(id,"_"), full.names = T)
    f = grep("x_ph_",f,value=T)
  }
  f_a = list.files(paste0(CELLSEGMENTATIONS_DIR,"Annotations"), pattern = paste0(id,"_"), full.names = T)
  f_o = list.files(paste0(CELLSEGMENTATIONS_DIR,"Images"), pattern = paste0(id,"_"), full.names = T)
  print(paste0("QPath output found for ",fileparts(f[1])$name," and ",(length(f)-1)," other image files."), quote = F)
  
  
  ## Read automated image analysis output
  cellCounts = matrix(NA,length(f),2);
  colnames(cellCounts) = c("areaCount","area_cm2")
  rownames(cellCounts) = sapply(f, function(x) fileparts(x)$name)
  # pdf(OUTSEGF)
  for(i in 1:length(f)){
    dm = read.table(f[i],sep="\t", check.names = F, stringsAsFactors = F, header = T)
    anno = read.table(f_a[i],sep="\t", check.names = T, stringsAsFactors = F, header = T)
    colnames(anno) = tolower(colnames(anno))
    areaCount = nrow(dm)
    area_cm2 = anno$`area.µm.2`[1]*UM2CM^2
    cellCounts[fileparts(f[i])$name,] = c(areaCount, area_cm2)
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
  print(paste("Estimated number of cells in entire flask at",dishCount), quote = F)
  
  if(!is.na(cellCount) && (dishCount/cellCount > 2 || dishCount/cellCount <0.5)){
    warning(paste0("Automated image analysis deviates from input cell count by more than a factor of 2. CellCount set to the former (",dishCount," cells)"))
  }
  return(dishCount)
}


.QuPathScript <- function(qpdir, cellLine){
  # Standard pipeline:
  runPlugin = "runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{\"detectionImage\": \"Red\",  \"backgroundRadius\": 15.0,  \"medianRadius\": 0.0,  \"sigma\": 3.0,  \"minArea\": 10.0,  \"maxArea\": 1000.0,  \"threshold\":0.09,  \"watershedPostProcess\": true,  \"cellExpansion\": 5.0,  \"includeNuclei\": true,  \"smoothBoundaries\": false,  \"makeMeasurements\": true}');"
  # # NCI-N87 pipeline:
  if(cellLine=="NCI-N87"){
    # runPlugin = "runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{\"detectionImageBrightfield\": \"Hematoxylin OD\",  \"requestedPixelSizeMicrons\": 0.5,  \"backgroundRadiusMicrons\": 8.0,  \"medianRadiusMicrons\": 0.0,  \"sigmaMicrons\": 1.5,  \"minAreaMicrons\": 40.0,  \"maxAreaMicrons\": 400.0,  \"threshold\": 0.09,  \"maxBackground\": 3.0,  \"watershedPostProcess\": false,  \"cellExpansionMicrons\": 5.0,  \"includeNuclei\": false,  \"smoothBoundaries\": true,  \"makeMeasurements\": true}');"
    runPlugin = "runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{\"detectionImageBrightfield\": \"Hematoxylin OD\",  \"requestedPixelSizeMicrons\": 0.461,  \"backgroundRadiusMicrons\": 12.0,  \"medianRadiusMicrons\": 0.0,  \"sigmaMicrons\": 1,  \"minAreaMicrons\": 5,  \"maxAreaMicrons\": 200.0,  \"threshold\": 0.2,  \"maxBackground\": 3.0,  \"watershedPostProcess\": true,  \"cellExpansionMicrons\": 1.0,  \"includeNuclei\": false,  \"smoothBoundaries\": true,  \"makeMeasurements\": true}');"
  }
  # HGC-27 pipeline:
  if(cellLine=="HGC-27"){
    runPlugin = "runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{\"detectionImageBrightfield\": \"Hematoxylin OD\",  \"requestedPixelSizeMicrons\": 0.5,  \"backgroundRadiusMicrons\": 8.0,  \"medianRadiusMicrons\": 0.0,  \"sigmaMicrons\": 1.5,  \"minAreaMicrons\": 90.0,  \"maxAreaMicrons\": 1200.0,  \"threshold\": 0.1,  \"maxBackground\": 2.0,  \"watershedPostProcess\": false,  \"cellExpansionMicrons\": 5.0,  \"includeNuclei\": false,  \"smoothBoundaries\": true,  \"makeMeasurements\": true}');"
  }
  # NUGC-4 pipeline:
  if(cellLine=="NUGC-4"){
    runPlugin = "runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{\"detectionImageBrightfield\": \"Hematoxylin OD\",  \"requestedPixelSizeMicrons\": 0.922,  \"backgroundRadiusMicrons\": 8.0,  \"medianRadiusMicrons\": 2.0,  \"sigmaMicrons\": 1.5,  \"minAreaMicrons\": 10.0,  \"maxAreaMicrons\": 200.0,  \"threshold\": 0.1,  \"maxBackground\": 2.9,  \"watershedPostProcess\": true,  \"cellExpansionMicrons\": 2.5,  \"includeNuclei\": false,  \"smoothBoundaries\": true,  \"makeMeasurements\": true}');"
  }
  qpdir = normalizePath(qpdir)
  paste(" import static qupath.lib.gui.scripting.QPEx.*"
        ," import qupath.lib.gui.tools.MeasurementExporter"
        ," import qupath.lib.objects.PathCellObject"
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
        ," print(pixelWidth);"
        ," print(pixelHeight);"
        ," "
        ," def filename = entry.getImageName() + '.csv'"
        , "// @TODO: read this info directly from .tif metadata"
        ,"if(pixelWidth == Double.NaN){"
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
        ,"}"
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
        ," "
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
