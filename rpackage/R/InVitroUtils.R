seed <- function(id, from, cellCount, tx = Sys.time(), dishSurfaceArea_cm2 = 25, PIXEL2CM = 1E-4){
  .seed_or_harvest(event = "seeding", id=id, from = from, cellCount = cellCount, tx = tx, dishSurfaceArea_cm2 = dishSurfaceArea_cm2, PIXEL2CM = PIXEL2CM)
}

harvest <- function(id, from, cellCount, tx = Sys.time(), dishSurfaceArea_cm2 = 25, PIXEL2CM = 1E-4){
  .seed_or_harvest(event = "harvest", id=id, from=from, cellCount = cellCount, tx = tx, dishSurfaceArea_cm2 = dishSurfaceArea_cm2, PIXEL2CM = PIXEL2CM)
}

.seed_or_harvest <- function(event, id, from, cellCount, tx, dishSurfaceArea_cm2, PIXEL2CM){
  QUPATH_DIR="~/QuPath/output/"; ##TODO: should be set under settings, not here
  EVENTTYPES = c("seeding","harvest")
  otherevent = EVENTTYPES[EVENTTYPES!=event]
  
  try(lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect))
  yml = yaml::read_yaml(paste0(system.file(package='cloneid'), '/config/config.yaml'))
  mydb = dbConnect(MySQL(), user=yml$mysqlConnection$user, password=yml$mysqlConnection$password, dbname=yml$mysqlConnection$database,host=yml$mysqlConnection$host, port=as.integer(yml$mysqlConnection$port))
  
  stmt = paste0("select * from Passaging where id = '",from,"'");
  rs = dbSendQuery(mydb, stmt)
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
  
  
  ### Insert
  ## @TODO: event cannot be NULL!
  passage = kids$passage
  if(event=="seeding"){
    passage = passage+1
  }
  stmt = paste0("INSERT INTO Passaging (id, passaged_from_id1, event, date, cellCount, passage) ",
                "VALUES ('",id ,"', '",from,"', '",event,"', '",tx,"', ",cellCount,", ", passage, ");") 
  rs = dbSendQuery(mydb, stmt)
  
  ## Wait and look for imaging analysis output
  print(paste0("Waiting for ",id,".txt to appear under ",QUPATH_DIR," ..."), quote = F)
  f = paste0(QUPATH_DIR,id,".txt")
  while(!file.exists(f)){
    Sys.sleep(3)
  }
  print(paste0(QUPATH_DIR,id,".txt found!"), quote = F)
  
  ## Read automated image analysis output
  dm = read.table(f,sep="\t", check.names = F, stringsAsFactors = F, header = T)
  areaCount = sum(dm$Name=="PathCellObject")
  area2dish = dishSurfaceArea_cm2 / (dm$Area.px.2[dm$Name=="PathAnnotationObject"] * PIXEL2CM^2)
  dishCount = round(areaCount * area2dish)
  ##@TODO: deal with PIXEL2CM conversion automatcially
  
  ## Update table with cell counts from automated image analysis
  stmt = paste0( "UPDATE Passaging", 
                " SET cellCount = ", dishCount,
                " WHERE id = '",id ,"'");
  rs = dbSendQuery(mydb, stmt);
  if(dishCount/cellCount > 2 || dishCount/cellCount <0.5){
    warning(paste0("Automated image analysis deviates from input cell count by more than a factor of 2. CellCount set to the former (",dishCount," cells)"))
  }
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
}

readGrowthRate <- function(cellLine){
  cmd = paste0("select P2.*, P1.cellCount, P2.cellCount, DATEDIFF(P2.date, P1.date), POWER(P2.cellCount / P1.cellCount, 1 / DATEDIFF(P2.date, P1.date)) as GR_per_day",
         " FROM Passaging P1 JOIN Passaging P2",
         " ON P1.id = P2.passaged_from_id1",
         " WHERE P2.event='harvest' and P1.cellLine='",cellLine,"'") 
  print(cmd, quote = F)
  
  try(lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect))
  yml = yaml::read_yaml(paste0(system.file(package='cloneid'), '/config/config.yaml'))
  mydb = dbConnect(MySQL(), user=yml$mysqlConnection$user, password=yml$mysqlConnection$password, dbname=yml$mysqlConnection$database,host=yml$mysqlConnection$host, port=as.integer(yml$mysqlConnection$port))
  
  rs = dbSendQuery(mydb, cmd)
  kids = fetch(rs, n=-1)
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  return(kids)
}

