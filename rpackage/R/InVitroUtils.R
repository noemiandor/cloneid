seed <- function(id, from, cellCount, dishSurfaceArea_cm2, tx = Sys.time(), media=NULL){ 
  ## Typical values for dishSurfaceArea_cm2 are: 
  ## a) 75 cm^2 = 10.1 cm x 7.30 cm  
  ## b) 25 cm^2 = 5.08 cm x 5.08 cm
  ## c) well from 96-plate = 0.32 cm^2
  .seed_or_harvest(event = "seeding", id=id, from = from, cellCount = cellCount, tx = tx, dishSurfaceArea_cm2 = dishSurfaceArea_cm2, media = media)
}


harvest <- function(id, from, cellCount, tx = Sys.time(), media=NULL){
  .seed_or_harvest(event = "harvest", id=id, from=from, cellCount = cellCount, tx = tx, dishSurfaceArea_cm2 = NULL, media = media)
}


feed <- function(id, tx=Sys.time()){
  library(RMySQL)
  mydb = .connect2DB()
  
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
  stmt = paste0("select * from Passaging where id IN ",paste0("('",paste0(ids, collapse = "', '"),"')  order by date DESC"));
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
  alllineages = c()
  out = list();
  for(id in parents$id){
    d = c(id, .traceDescendands(id))
    d = setdiff(d, alllineages); ## exclude descendands with more recent parent (i.e. seedings)
    alllineages = c(alllineages, d)
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
  rs = dbSendQuery(mydb, "select name, year_of_first_report, doublingTime_hours from CellLinesAndBiopsies where year_of_first_report >0;")
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

.seed_or_harvest <- function(event, id, from, cellCount, tx, dishSurfaceArea_cm2, media){
  library(RMySQL)
  library(matlab)
  UM2CM = 1e-4
  ## QuPath Settings; TODO: should be set under settings, not here
  QUPATH_DIR="~/QuPath/output/"; 
  dir.create("~/Downloads/qpscript")
  write(QuPathScript(qpdir = QUPATH_DIR), file="~/Downloads/qpscript/runDetectionROI.groovy")
  qpversion = gsub(".app","", strsplit(list.files("/Applications", pattern = "QuPath")[1],"-")[[1]][2])
  
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
  if(is.na(kids$media)){
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
  
  ## dishSurfaceArea_cm2 cannot have changed if this is a harvest event: 
  if(event=="harvest"){
    dishSurfaceArea_cm2 = kids$dishSurfaceArea_cm2
  }
  
  ##OK @TODO: ask Martina to create separate folder qpdata and move all qpdata files there
  ##OK @TODO: ask Martina to copy 10xph images for latest SNU-16 to ~/QuPath to replace old ones (4x)
  ##OK @TODO: replace Downloads/qptest with ~/QuPath
  f_i = list.files("~/QuPath", pattern = paste0(id,"_10x_ph_"), full.names = T)
  ##OK @TODO: copy images into temp directory
  unlink("~/Downloads/tmp",recursive=T)
  dir.create("~/Downloads/tmp")
  file.copy(f_i, "~/Downloads/tmp/")
  ## @TODO: call QuPath, then remove image-copies
  cmd = paste0("java -jar /Applications/QuPath-",qpversion,".app/Contents/app/qupath-",qpversion,".jar -image ~/Downloads/qptest script ~/Downloads/runCellDetectionROI.groovy")
  
  
  ## Wait and look for imaging analysis output
  print(paste0("Waiting for ",id,".txt to appear under ",QUPATH_DIR," ..."), quote = F)
  ##OK @TODO: replace Downloads/qpresults with QUPATH_DIR (also in groovy script)
  f = list.files(paste0(QUPATH_DIR,"DetectionResults"), pattern = paste0(id,"_10x_ph_"), full.names = T)
  f_a = list.files(paste0(QUPATH_DIR,"Annotations"), pattern = paste0(id,"_10x_ph_"), full.names = T)
  while(length(f)<length(f_i)){
    Sys.sleep(3)
  }
  print(paste0("QPath output found for ",fileparts(f[1])$name," and ",(length(f)-1)," other image files."), quote = F)
  
  ## Read automated image analysis output
  par(mfrow=c(2,2))
  cellCounts = matrix(NA,length(f),2);
  colnames(cellCounts) = c("areaCount","area_cm2")
  rownames(cellCounts) = sapply(f, function(x) fileparts(x)$name)
  for(i in 1:length(f)){
    dm = read.table(f[i],sep="\t", check.names = F, stringsAsFactors = F, header = T)
    anno = read.table(f_a[i],sep="\t", check.names = F, stringsAsFactors = F, header = T)
    margins = apply(dm[,c("Centroid X µm","Centroid Y µm")],2,quantile,c(0,1), na.rm=T)
    ## Adjust by cell radius:
    cellRad = median(dm$`Cell: Perimeter`)/(2*pi) 
    margins[2,] = margins[2,] + cellRad;
    margins[1,] = margins[1,] - cellRad
    width_height = (margins[2,]- margins[1,])*UM2CM
    areaCount = nrow(dm)
    # area_cm2 = width_height[1] * width_height[2]; 
    area_cm2 = anno$`Area µm^2`[1]*UM2CM^2
    cellCounts[fileparts(f[i])$name,] = c(areaCount, area_cm2)
    ## Visualize
    la=tiff::readTIFF(f_i[i])
    plot(0,0, xlim=margins[,1], ylim=sort(-margins[,2]),type="n",ann=FALSE,axes=FALSE, main = fileparts(f_i[i])$name)
    rasterImage(la,margins[1,1],-margins[2,2],margins[2,1],-margins[1,2],)
    points(dm$`Centroid X µm`,-dm$`Centroid Y µm`, col="red", cex=0.1)
    rect(margins[1,1], -margins[2,2], margins[2,1], -margins[1,2], col=NULL, border = "red")
  }
  area2dish = dishSurfaceArea_cm2 / sum(cellCounts[,"area_cm2"])
  dishCount = round(sum(cellCounts[,"areaCount"]) * area2dish)
  
  ### Insert
  passage = kids$passage
  if(event=="seeding"){
    passage = passage+1
  }
  stmt = paste0("INSERT INTO Passaging (id, passaged_from_id1, event, date, cellCount, passage, dishSurfaceArea_cm2, media) ",
                "VALUES ('",id ,"', '",from,"', '",event,"', '",tx,"', ",dishCount,", ", passage,", ",dishSurfaceArea_cm2,", ", kids$media, ");") 
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

QuPathScript<-function(qpdir = normalizePath("~/QuPath/output")){
  paste("import static qupath.lib.gui.scripting.QPEx.*",
        "import qupath.lib.gui.tools.MeasurementExporter",
        "import qupath.lib.objects.PathCellObject",
        "import qupath.lib.objects.PathDetectionObject",
        "",
        "",
        "//  User enter these information for every project.",
        "//*************************************************",
        "def PixelWidth_new = 1.000;",
        "def PixelHeight_new = 1.000;",
        "def x_left = 100;",
        "def y_left = 100;",
        "def w_ROI =  1100;",
        "def h_ROI = 1100;",
        "//*************************************************",
        "",
        "",
        "def project = getProject()",
        "def entry = getProjectEntry()",
        "def imageData = entry.readImageData()",
        "def CurrentImageData = getCurrentImageData()",
        "def hierarchy = imageData.getHierarchy()",
        "def annotations = hierarchy.getAnnotationObjects()",
        "",
        "def server = CurrentImageData.getServer()",
        "def path = server.getPath()",
        "def cal = server.getPixelCalibration();",
        "double pixelWidth = cal.getPixelWidthMicrons();",
        "double pixelHeight = cal.getPixelHeightMicrons();",
        "",
        "print(pixelWidth);",
        "print(pixelHeight);",
        "if(pixelWidth == Double.NaN){",
        "    setPixelSizeMicrons(PixelWidth_new, PixelWidth_new);",
        " ",
        "}",
        "",
        "",
        "setImageType('BRIGHTFIELD_H_E');",
        "setColorDeconvolutionStains('{\"Name\" : \"H&E default\", \"Stain 1\" : \"Hematoxylin\", \"Values 1\" : \"0.65111 0.70119 0.29049 \", \"Stain 2\" : \"Eosin\", \"Values 2\" : \"0.2159 0.8012 0.5581 \", \"Background\" : \" 255 255 255 \"}');",
        "def plane = ImagePlane.getPlane(0,0);",
        "def rectangle = ROIs.createRectangleROI(x_left,y_left,w_ROI,h_ROI,plane);",
        "def rectangleAnnotation = PathObjects.createAnnotationObject(rectangle);",
        "QPEx.addObjects(rectangleAnnotation);",
        "println \"Success\";",
        "//createSelectAllObject(true);",
        "selectAnnotations();",
        "runPlugin('qupath.imagej.detect.cells.WatershedCellDetection', '{\"detectionImage\": \"Red\",  \"backgroundRadius\": 15.0,  \"medianRadius\": 0.0,  \"sigma\": 3.0,  \"minArea\": 10.0,  \"maxArea\": 1000.0,  \"threshold\":0.09,  \"watershedPostProcess\": true,  \"cellExpansion\": 5.0,  \"includeNuclei\": true,  \"smoothBoundaries\": false,  \"makeMeasurements\": true}');",
        "",
        "",
        "",
        "def filename = entry.getImageName() + '.csv'",
        "selectDetections()",
        paste0("def pathDetection = buildFilePath('",qpdir,"/DetectionResults');"),
        paste0("def pathAnnotation = buildFilePath('",qpdir,"/Annotations')"),
        "mkdirs(pathDetection);",
        "mkdirs(pathAnnotation);",
        "pathDetection = buildFilePath(pathDetection, filename);",
        "pathAnnotation = buildFilePath(pathAnnotation, filename);",
        "saveDetectionMeasurements(pathDetection);",
        "saveAnnotationMeasurements(pathAnnotation)", sep="\n" )
}