# The seed function records a new seeding event in the database.

seed <- function(id, from, cellCount, flask, tx = Sys.time(), media=NULL, excludeOption=F, preprocessing=T, param=NULL) {
  # Retrieve the name of the current function for logging purposes.
  function_name <- as.character(match.call()[[1]])

  tryCatch({
  # Call the internal .seed_or_harvest function to handle the seeding event and store the result in 'x'.
    x <- .seed_or_harvest(
      event = "seeding",
      id = id,
      from = from,
      cellCount = cellCount,
      tx = tx,
      flask = flask,
      media = media,
      excludeOption = excludeOption,
      preprocessing = preprocessing,
      param = param
    )
  }, error = function(error) {
    # Log the error with the function name and message.
    backend_message("ERR", function_name, error$message)

    # Re-throw the error to allow for further handling up the call stack if desired.
    stop(error)
  })

  # Return the result of the seeding event.
  return(x)
}

harvest <- function(id, from, cellCount, tx = Sys.time(), media=NULL, excludeOption=F, preprocessing=T, param=NULL){
  functionName<-as.character(match.call()[[1]])
  x=.seed_or_harvest(event = "harvest", id=id, from=from, cellCount = cellCount, tx = tx, flask = NULL, media = media, excludeOption=excludeOption, preprocessing=preprocessing, param=param)
  return(x)
}


feed <- function(id, tx=Sys.time()){

  # readLines(textConnection(capture.output(lsf.str())))

  functionName<-as.character(match.call()[[1]])
  if(!dbX){library(RMySQL)}
  if(!dbX){mydb = connect2DB()}
  
  stmt = paste0("SELECT * FROM Passaging WHERE id='",id,"'");
  if(!dbX){rs   = suppressWarnings(dbSendQuery(mydb, stmt))}
  if(!dbX){kids = fetch(rs, n=-1)}
  if( dbX){kids = dbFetchResults(stmt, functionName) }
  
  ### Checks
  if (kids$event=="harvest"){
    # print("Cannot feed cells that have already been harvested.", quote = F); 
    backend_message("PRNT",'(kids$event=="harvest")', "Cannot feed cells that have already been harvested.");
  }
  
  priorfeedings = kids[grep("feeding",names(kids),value=T)]
  ## Next un-occupied feeding index
  nextI = apply(!is.na(priorfeedings),1,sum)+1
  if(nextI>length(priorfeedings)){
    # print(paste0("Cannot record more than ",length(priorfeedings)," feedings. Add additional feeding column first."), quote = F); 
    backend_message("PRNT","(nextI>length(priorfeedings))", paste0("Cannot record more than ",length(priorfeedings)," feedings. Add additional feeding column first."));
  }
  
  ### Insert
  stmt = paste0("UPDATE Passaging SET ",names(priorfeedings)[nextI],"='",tx,"' where id='",id ,"'") 
  if(!dbX){rs = dbSendQuery(mydb, stmt)}
  if( dbX){rs = dbFetchResults(mydb, functionName)}
  # print(paste("Feeding for",id,"recorded at",tx), quote = F);
  backend_message("PRNT",functionName,paste("Feeding for",id,"recorded at",tx));
  
  if(!dbX){dbClearResult(dbListResults(mydb)[[1]])}
  if(!dbX){dbDisconnect(mydb)}
}

## Read dishSurfaceArea_cm2 of this flask 
.readDishSurfaceArea_cm2 <- function(flask, mydb = NULL){
  functionName<-as.character(match.call()[[1]])
  if(is.null(mydb)){
    if(!dbX){mydb = connect2DB()}
  }
  stmt = paste0("select dishSurfaceArea_cm2 from Flask where id = ", flask)
  if(!dbX){rs = suppressWarnings(dbSendQuery(mydb, stmt))}
  if(!dbX){dishSurfaceArea_cm2 = fetch(rs, n=-1)}
  if( dbX){dishSurfaceArea_cm2 = dbFetchResults(stmt, functionName)}
  if(nrow(dishSurfaceArea_cm2)==0){
    # print("Flask does not exist in database or its surface area is not specified")
    backend_message("ABRT",'(nrow(dishSurfaceArea_cm2)==0)',"Flask does not exist in database or its surface area is not specified");
    # stopifnot(nrow(dishSurfaceArea_cm2)>0)
  }
  return(dishSurfaceArea_cm2[[1]])
}


findAllDescendandsOf <-function(ids, mydb = NULL, recursive = T, verbose = T){
  functionName<-as.character(match.call()[[1]])
  if(!dbX){library(RMySQL)}
  
  if(is.null(mydb)){
    if(!dbX){mydb = connect2DB()}
  }
  stmt = paste0("select * from Passaging where id IN ",paste0("('",paste0(ids, collapse = "', '"),"')  order by date DESC"));
  if(!dbX){rs = suppressWarnings(RMySQL::dbSendQuery(mydb, stmt))}
  if(!dbX){parents = fetch(rs, n=-1)}
  if( dbX){parents = dbFetchResults(stmt, functionName)}
  
  ## Recursive function to trace descendands
  .traceDescendands<-function(x){
    functionName<-as.character(match.call()[[1]])
    stmt = paste0("select * from Passaging where passaged_from_id1 = '",x,"'");
    if(!dbX){rs = suppressWarnings(RMySQL::dbSendQuery(mydb, stmt))}
    if(!dbX){kids = fetch(rs, n=-1)}
    if( dbX){kids = dbFetchResults(stmt, functionName)}
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
    # print(stmt)
    backend_message("PRNT",functionName,stmt);
  }
  
  ## Get results from DB
  if(!dbX){rs = suppressWarnings(RMySQL::dbSendQuery(mydb, stmt))}
  if(!dbX){res = fetch(rs, n=-1)}
  if( dbX){res = dbFetchResults(stmt, functionName)}
  
  if(!dbX){dbDisconnect(mydb)}
  
  return(res)
}


.seed_or_harvest <- function(event, id, from, cellCount, tx, flask, media, excludeOption, preprocessing=T, param=NULL){
  functionName<-as.character(match.call()[[1]])

  if(!dbX){library(RMySQL)}
  library(matlab)
  
  EVENTTYPES = c("seeding","harvest")
  otherevent = EVENTTYPES[EVENTTYPES!=event]
  if(!dbX){mydb = connect2DB()}

  backend_message("INFO","ARGS",paste(c(functionName, event, id, from, cellCount, tx, flask, media, excludeOption, preprocessing, param), collapse = "::"))

  stmt = paste0("SELECT * FROM Passaging WHERE id='",from,"'");
  if(!dbX){rs = suppressWarnings(dbSendQuery(mydb, stmt))}
  if(!dbX){kids = fetch(rs, n=-1)}
  if( dbX){kids = dbFetchResults(stmt, functionName)}
  backend_message("MESG", 'info', "DB Access Passaging"); 
  backend_message("MESG", 'info', kids); 
  
  ### Checks
  CHECKRESULT="pass"
  
  #TESTING
  if(IVUTEST_CHECKRESULT==TRUE || Sys.getenv("IVUTEST_CHECKRESULT")=="TRUE"){
    CHECKRESULT="Something Strange happened"
  }

  if(nrow(kids)==0){
    CHECKRESULT=paste(from,"does not exist in table Passaging")
    backend_message("INFO","CHECKRESULT (nrow(kids)==0)",CHECKRESULT)
  }else if(kids$event !=otherevent){
    CHECKRESULT=paste(from,"is not a",otherevent,". You must do",event,"from a",otherevent)
    backend_message("INFO","CHECKRESULT kids$event !=otherevent",CHECKRESULT)
  }else if(event=="seeding" && !is.na(kids$cellCount) && !is.na(cellCount) && cellCount>kids$cellCount){
    CHECKRESULT="You cannot seed more than is available from harvest!"
    backend_message("INFO","CHECKRESULT (event==seeding && !is.na(kids$cellCount) && !is.na(cellCount) && cellCount>kids$cellCount)",CHECKRESULT)
  }else if(is.na(kids$media) || !is.null(media)){
    if(is.null(media)){
      CHECKRESULT="Please enter media information"
      backend_message("INFO","CHECKRESULT is.null(media)",CHECKRESULT)
    }else{
      kids$media = media
    }
  }else{
    # warning(paste("Copying media information from parent: media set to",kids$media))
    backend_message("NTIF", 'info', paste("Copying media information from parent: media set to",kids$media));
  }
  
  if(CHECKRESULT!="pass"){
    confirmError = "no"
      #                     _ _ _            
      #  _ __ ___  __ _  __| | (_)_ __   ___ 
      # | '__/ _ \/ _` |/ _` | | | '_ \ / _ \
      # | | |  __/ (_| | (_| | | | | | |  __/
      # |_|  \___|\__,_|\__,_|_|_|_| |_|\___|
      #  
      #   while(confirmError!="yes"){
      #     confirmError <- readline(prompt=paste0("Error encountered while updating database: ",CHECKRESULT,". No changes were made to the database. Type yes to confirm: "))
      #   }
    
    inputOptions <- c("Yes")
    infomessage <- paste0("Error encountered while updating database: '",CHECKRESULT,"'. No changes were made to the database.")
    prompt <- paste0("Select yes to confirm: ")
    retry_prompt <- "Invalid input. Please enter a valid option number or type one of the provided inputOptions."
    selected_option <- handleUserInput(inputOptions, prompt, retry_prompt, infomessage)
    backend_message("QUIT", functionName, CHECKRESULT);
    Sys.sleep(10)
    q()
    # return(NULL) # ENDS PROCESSING
  }
  ## TODO: What if from is too far in the past
  
  ## flask cannot have changed if this is a harvest event: 
  if(event=="harvest"){
    flask = kids$flask
  }
  
  backend_message("MESG", 'info', "DB Access Flask"); 
  dishSurfaceArea_cm2 = .readDishSurfaceArea_cm2(flask, mydb)
  
  dish = .readCellSegmentationsOutput(id= id, from=from, cellLine = kids$cellLine, dishSurfaceArea_cm2 = dishSurfaceArea_cm2, cellCount = cellCount, excludeOption=excludeOption, preprocessing=preprocessing, param=param);
  
  ### Passaging info
  passage = kids$passage
  if(event=="seeding"){
    passage = passage+1
  }
  
  ## User info
  if(!dbX){mydb = connect2DB()}
  if(!dbX){rs  = suppressWarnings(dbSendQuery(mydb, "SELECT user()"));}
  if(!dbX){user= fetch(rs, n=-1)[,1];}
  if( dbX){user= dbFetchUser()}
  backend_message("MESG", 'info', "DB Access Flask"); 
  
  ### Check id, passaged_from_id1: is there potential for incorrect assignment between them?
  stmt = "SELECT id, event, passaged_from_id1, correctedCount,passage, date from Passaging";
  if(!dbX){rs = suppressWarnings(dbSendQuery(mydb, stmt))}
  if(!dbX){passaging = fetch(rs, n=-1)}
  if( dbX){passaging = dbFetchResults(stmt, functionName)}
  rownames(passaging) <- passaging$id
  passaging$passage_id <- sapply(passaging$id, .unique_passage_id)
  # x=data.table::transpose(as.data.frame(c(id , event, from, dish$dishCount, passage)))
  # colnames(x) = c("id", "event", "passaged_from_id1", "correctedCount", "passage")
  x=data.table::transpose(as.data.frame( c(id  , from,                event,   tx,     dish$dishCount, dish$dishCount,   dish$cellSize,  dish$dishAreaOccupied, passage,   flask,   kids$media, user,    user,           transactionId)))
  colnames(x) =                          c("id", "passaged_from_id1", "event", "date", "cellCount",    "correctedCount", "cellSize_um2", "areaOccupied_um2",    "passage", "flask", "media",    "owner", "lastModified", "transactionId")
  rownames(x) <- x$id
  x4DB <- x
  x$passage_id <- .unique_passage_id(x$id)
  probable_ancestor <- try(.assign_probable_ancestor(x$id,xi=passaging), silent = T)
  ancestorCheck = T;
  if(class(probable_ancestor)!="try-error" && !isempty(probable_ancestor) ){
    x$probable_ancestor = probable_ancestor
    if(x$passaged_from_id1!=x$probable_ancestor){
      confirmAncestorCorrect = ""
      #                     _ _ _            
      #  _ __ ___  __ _  __| | (_)_ __   ___ 
      # | '__/ _ \/ _` |/ _` | | | '_ \ / _ \
      # | | |  __/ (_| | (_| | | | | | |  __/
      # |_|  \___|\__,_|\__,_|_|_|_| |_|\___|
      #  
      ancestorCheck=F;
      ## @TODO: this is redundant code. Write short function for this and use it everywhere.
      # confirmError = "no"
      # while(confirmError!="yes"){
      #   confirmError <- readline(prompt="No changes are made to the database. Please modify passaged_from_id1, then rerun. Type yes to confirm: ")
      # }
      inputOptions <- c("Yes", "No")
      infomessage <- paste0("Warning encountered while updating database: Was ",x$id," really derived from ",x$passaged_from_id1,"?")
      prompt <- paste0("Select one option: ")
      retry_prompt <- "Invalid input. Please enter a valid option number or type one of the provided options."
      selected_option <- handleUserInput(inputOptions, prompt, retry_prompt, infomessage)
      # while(!confirmAncestorCorrect %in% c("yes", "no")){
      #   confirmAncestorCorrect <- readline(prompt=paste0("Warning encountered while updating database: Was ",x$id," really derived from ",x$passaged_from_id1,"? type yes/no: "))
      # }
      # if(confirmAncestorCorrect=="no"){
      if(selected_option==2){
        #                     _ _ _            
        #  _ __ ___  __ _  __| | (_)_ __   ___ 
        # | '__/ _ \/ _` |/ _` | | | '_ \ / _ \
        # | | |  __/ (_| | (_| | | | | | |  __/
        # |_|  \___|\__,_|\__,_|_|_|_| |_|\___|
        #  
        ancestorCheck=F;
        ## @TODO: this is redundant code. Write short function for this and use it everywhere.
        # confirmError = "no"
        # while(confirmError!="yes"){
        #   confirmError <- readline(prompt="No changes are made to the database. Please modify passaged_from_id1, then rerun. Type yes to confirm: ")
        # }
        inputOptions <- c("Yes")
        infomessage <- paste0("No changes are made to the database. Please modify 'passaged_from_id1', then rerun.")
        prompt <- paste0("Select yes to confirm: ")
        retry_prompt <- "Invalid input. Please enter a valid option number or type one of the provided inputOptions."
        selected_option <- handleUserInput(inputOptions, prompt, retry_prompt, infomessage)
      }
    }
  }
  
  ## non-numeric entries formatting:
  ii=which(!names(x) %in% c("cellSize_um2","areaOccupied_um2","correctedCount","cellCount", "passage", "flask", "media"))
  x[ii]=paste0("'",x[ii],"'")
  x4DB <- x[names(x4DB)]
  # backend_message("INFO", "415 II",ii);backend_message("INFO", "415 x4DB",x4DB); 
  ## Attempt to update the DB:
  if(ancestorCheck){
    ### Insert
    # stmt = paste0("INSERT INTO Passaging (id, passaged_from_id1, event, date, cellCount, passage, flask, media, owner, lastModified) ",
    # "VALUES ('",id ,"', '",from,"', '",event,"', '",tx,"', ",dish$dishCount,", ", passage,", ",flask,", ", kids$media, ", '", user, "', '", user, "');")
    stmt = paste0("INSERT INTO Passaging (",paste(names(x4DB), collapse = ", "),") ",
                  "VALUES (",paste(x4DB, collapse = ", "),");")
    if(!dbX){rs = try(dbSendQuery(mydb, stmt))}
    if( dbX){rs = try(dbLoadResults(stmt, functionName))}
    
    if(class(rs)!="try-error"){
      stmt = paste0("update Passaging set correctedCount = ",x4DB$correctedCount," where id='",id,"';")
      if(!dbX){rs = dbSendQuery(mydb, stmt)}
      if( dbX){rs = dbLoadResults(stmt, functionName)}
      
      stmt = paste0("update Passaging set areaOccupied_um2 = ",x4DB$areaOccupied_um2," where id='",id,"';")
      if(!dbX){rs = dbSendQuery(mydb, stmt)}
      if( dbX){rs = dbLoadResults(stmt, functionName)}
      
      stmt = paste0("update Passaging set cellSize_um2 = ",x4DB$cellSize_um2," where id='",id,"';")
      if(!dbX){rs = dbSendQuery(mydb, stmt)}
      if( dbX){rs = dbLoadResults(stmt, functionName)}
    }else{
      # confirmError = "no"
      # while(confirmError!="yes"){
        #                     _ _ _            
        #  _ __ ___  __ _  __| | (_)_ __   ___ 
        # | '__/ _ \/ _` |/ _` | | | '_ \ / _ \
        # | | |  __/ (_| | (_| | | | | | |  __/
        # |_|  \___|\__,_|\__,_|_|_|_| |_|\___|
        #  
        # confirmError <- readline(prompt="Error encountered while updating database: no changes were made to the database. Please check id is not redundant with existing IDs, then rerun. Type yes to confirm: ")
      # }
        
      inputOptions <- c("Yes")
      infomessage <- paste(
        c(
          "Error encountered while updating database:",
          "no changes were made to the database.",
          paste0("Please check ", id, " is not redundant with existing IDs, then rerun")
        ),
       sep="\n"
      )
      prompt <- paste0("Select yes to confirm ")
      retry_prompt <- "Invalid input. Please enter a valid option number or type one of the provided inputOptions."
      selected_option <- handleUserInput(inputOptions, prompt, retry_prompt, infomessage)
      # backend_message("QUIT", functionName, id);
      # backend_message("NTIF", functionName, id);
    }
  }
  
  try(if(!dbX){dbClearResult(dbListResults(mydb)[[1]])}, silent = T)
  try(if(!dbX){dbDisconnect(mydb)}, silent = T)
  
  return(x4DB)
}

##find the unique string that identifies a passage
.unique_passage_id <- function(i){
  functionName<-as.character(match.call()[[1]])
  paste(head(unlist(strsplit(i,split="_")),3),collapse="_")
}

## Make suggestions to correct ancestor
.assign_probable_ancestor <- function(i,xi){
  functionName<-as.character(match.call()[[1]])
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
  functionName<-as.character(match.call()[[1]])
  ## Typical values for dishSurfaceArea_cm2 are: 
  ## a) 75 cm^2 = 10.1 cm x 7.30 cm  
  ## b) 25 cm^2 = 5.08 cm x 5.08 cm
  ## c) well from 96-plate = 0.32 cm^2
  ## CellSegmentations Settings; @TODO: should be set under settings, not here
  UM2CM = 1e-4
  
  # TODO remove FALSE
  if(!inbackend_session){
    yml = yaml::read_yaml(paste0(system.file(package='cloneid'), '/config/config.yaml'))
    TMP_DIR = normalizePath(yml$cellSegmentation$tmp);
    CELLSEGMENTATIONS_OUTDIR=paste0(normalizePath(yml$cellSegmentation$output),"/");
    CELLSEGMENTATIONS_INDIR=paste0(normalizePath(yml$cellSegmentation$input),"/");
  }else{
    if(TMP_DIR==''){
    TMP_DIR=getEnvSegmentationDir("TMP_DIR")
    CELLSEGMENTATIONS_OUTDIR=getEnvSegmentationDir("CELLSEGMENTATIONS_OUTDIR")
    CELLSEGMENTATIONS_INDIR=getEnvSegmentationDir("CELLSEGMENTATIONS_INDIR")
    RESULTS_DIR=getEnvSegmentationDir("RESULTS_DIR")        
    }
  }
  
  # QUPATH_PRJ = "~/Downloads/qproject/project.qpproj"
  # QSCRIPT = "~/Downloads/qpscript/runDetectionROI.groovy"
  CELLPOSE_PARAM=paste0(find.package("cloneid"),filesep,"python/cellPose.param")
  PYTHON_SCRIPTS=list.files(paste0(find.package("cloneid"),filesep,"python"), pattern=".py", full.names = T)
  CELLPOSE_SCRIPT=grep("GetCount_cellPose.py",PYTHON_SCRIPTS, value = T)
  PREPROCESS_SCRIPT=grep("preprocessing.py",PYTHON_SCRIPTS, value = T)
  TISSUESEG_SCRIPT=grep("tissue_seg.py",PYTHON_SCRIPTS, value = T)
  QCSTATS_SCRIPT=grep("QC_Statistics.py",PYTHON_SCRIPTS, value = T)
  
  detectionfilelist = list.files(paste0(CELLSEGMENTATIONS_OUTDIR,"DetectionResults"), pattern = paste0(id,"_"), full.names = T)
  inputfilelist = list.files(CELLSEGMENTATIONS_INDIR, pattern = paste0(id,"_"), full.names = T)
  if (length(inputfilelist)==length(detectionfilelist)){
    alreadyProcessed = TRUE
    discardPreviousResults = !alreadyProcessed
    backend_message("INFO","PROCESSED","TRUE")
    backend_message("INFO","PROCESSED",length(inputfilelist))
    backend_message("INFO","PROCESSED",length(detectionfilelist))
  }
  if(discardPreviousResults){
    unlink(CELLSEGMENTATIONS_OUTDIR,recursive=T)
    backend_message("INFO","CREATE",CELLSEGMENTATIONS_OUTDIR)
    dir.create(CELLSEGMENTATIONS_OUTDIR)
  }
  
  #suppressWarnings(dir.create(paste0(CELLSEGMENTATIONS_OUTDIR,"DetectionResults")))
  #suppressWarnings(dir.create(paste0(CELLSEGMENTATIONS_OUTDIR,"Annotations"))) 
  #suppressWarnings(dir.create(paste0(CELLSEGMENTATIONS_OUTDIR,"Images"))); 
  #suppressWarnings(dir.create(paste0(CELLSEGMENTATIONS_OUTDIR,"Confluency"))); 
  dir.create(paste0(CELLSEGMENTATIONS_OUTDIR,"DetectionResults"))
  dir.create(paste0(CELLSEGMENTATIONS_OUTDIR,"Annotations")) 
  dir.create(paste0(CELLSEGMENTATIONS_OUTDIR,"Images")); 
  dir.create(paste0(CELLSEGMENTATIONS_OUTDIR,"Confluency")); 
  # suppressWarnings(dir.create("~/Downloads/qpscript"))
  # suppressWarnings(dir.create(fileparts(QUPATH_PRJ)$pathstr))
  # qpversion = list.files("/Applications", pattern = "QuPath")
  # qpversion = gsub(".app","", gsub("QuPath","",qpversion))
  # qpversion = qpversion[length(qpversion)]
  
  ## Load environment and source python scripts
  #conda_list()
  LOADEDENV='cellpose' %in% conda_list()$name
  backend_message("INFO","cellpose",LOADEDENV)
  backend_message("INFO","cellpose",PYTHON_SCRIPTS)
  
  #LOADEDENV=F
  if(LOADEDENV){
  backend_message("INFO","LOADEDENV",LOADEDENV)
    use_condaenv("cellpose")
#     use_condaenv("cellpose", required = TRUE)
  #   sapply(PYTHON_SCRIPTS, source_python)
	for (script in PYTHON_SCRIPTS) {
		source_python_script(script)
	}
  }
  

  
  ## Copy raw images to temporary directory:
  if(discardPreviousResults){
    unlink(TMP_DIR,recursive=T)
    dir.create(TMP_DIR)
  }
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
      # print(paste("Using", PREPROCESS_SCRIPT))
      backend_message("PRNT",functionName,paste("Using", PREPROCESS_SCRIPT));
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
    if(!dbX){mydb = connect2DB()}
    stmt = paste0("select id, cellLine from Passaging where id in (\'",paste(setdiff(rownames(cpp),"default"),collapse = "', '"),"\') ")
    if(!dbX){rs = dbSendQuery(mydb, stmt)}
    if(!dbX){cli = fetch(rs, n=-1)}
    if( dbX){cli = dbFetchResults(stmt, functionName)}
    if(!dbX){dbClearResult(dbListResults(mydb)[[1]])}
    if(!dbX){dbDisconnect(mydb)}
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
  # print(param)
  backend_message("PRNT",functionName,param);
  
  if (!alreadyProcessed)
  {
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
  # print(paste0("Waiting for ",id," to appear under ",CELLSEGMENTATIONS_OUTDIR," ..."), quote = F)
  backend_message("PRNT",functionName,paste0("Waiting for ",id," to appear under ",CELLSEGMENTATIONS_OUTDIR," ..."));
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
  # print(paste0("Output found for ",fileparts(f[1])$name," and ",(length(f)-1)," other image files."), quote = F)
  backend_message("PRNT",functionName,paste0("Output found for ",fileparts(f[1])$name," and ",(length(f)-1)," other image files."));
  
  backend_message("RSLT","IMGS",CELLSEGMENTATIONS_OUTDIR);
  
  ## Read automated image analysis output
  cellCounts = matrix(NA,length(f),4);
  colnames(cellCounts) = c("areaCount","area_cm2","dishAreaOccupied", "cellSize_um2")
  rownames(cellCounts) = sapply(f, function(x) fileparts(x)$name)



  filesSuffixList <- sapply(f, function(x) {fn<-fileparts(x)$name; fl<-nchar(fn);print(substring(fn,fl-1,fl))})
      
  # pdf(OUTSEGF)
  for(i in 1:length(f)){
    dm = read.table(f[i],sep="\t", check.names = F, stringsAsFactors = F, header = T)
    colnames(dm)[colnames(dm)=="Area µm^2"]="Cell: Area"; ## Replace cellPose column name -- @TODO: saeed fix directly in cellposeScript
    anno = read.table(f_a[i],sep="\t", check.names = T, stringsAsFactors = F, header = T)
    conf = read.csv(f_c[i])
    colnames(anno) = tolower(colnames(anno))
    areaCount = nrow(dm)
    # areaCount = sum(conf$`Area.in.um`)/median(dm$`Cell: Area`)
    area_cm2 = anno$`area.µm.2`[1]*UM2CM^2
    ##
    subr1 = anno$`area.µm.2`
    backend_message("VARS", paste(fileparts(f[i])$name,'subr1'), subr1);
    subr2 = area_cm2
    backend_message("VARS", paste(fileparts(f[i])$name,'subr2'), subr2);
    subr3 = dm$`Cell: Area`
    backend_message("VARS", paste(fileparts(f[i])$name,'subr3'), subr3);
    write.csv(subr3, paste0(RESULTS_DIR,"subr3.csv"), row.names=T)
    subr4 = quantile(dm$`Cell: Area`, 0.9, na.rm=T)
    backend_message("VARS", paste(fileparts(f[i])$name,'subr4'), subr4);
    subr5 = c(areaCount, area_cm2, sum(conf$`Area.in.um`), quantile(dm$`Cell: Area`, 0.9, na.rm=T))
    backend_message("VARS", paste(fileparts(f[i])$name,'subr5'), subr5);
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
  # print("Predicting cell count error...",quote=F)
  backend_message("INFO", functionName, "Predicting cell count error...");
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
      # warning("No features for error prediction available", immediate. = T)
      excludeOption=T
      backend_message("NTIF", 'warning', "No features for error prediction available");
      # backend_message("VARS", 'excludeOption', TRUE);
      backend_message("VARS", 'excludeOption', jsonlite::toJSON(excludeOption));
      break;
    }
    anno$log.error = predict(linM, newdata=anno)
    if(anno$log.error>linM$MAXERROR){
      # warning("Low image quality predicted for at least one image")
      excludeOption=T
      backend_message("NTIF", 'warning', "Low image quality predicted for at least one image");
      # backend_message("VARS", 'excludeOption', TRUE);
      backend_message("VARS", 'excludeOption', jsonlite::toJSON(excludeOption));
      break;
    }else{
      # print(paste("Cell count error predicted as negligible for",f_a[i]),quote=F)
      backend_message("NTIF", 'info', paste("Cell count error predicted as negligible for", fileparts(f_a[i])$name));
    }
  }
  
  ## Provide option to exclude subset of images
  # if(length(filesSuffixList)>1 && excludeOption && !inbackend_session)
  if( length(filesSuffixList)>1 && excludeOption){
    # TODO: MANAGE EXCLUDE IMAGES
    #                     _ _ _            
    #  _ __ ___  __ _  __| | (_)_ __   ___ 
    # | '__/ _ \/ _` |/ _` | | | '_ \ / _ \
    # | | |  __/ (_| | (_| | | | | | |  __/
    # |_|  \___|\__,_|\__,_|_|_|_| |_|\___|
    #  
    

    excludePrompt=paste(c("Exclude any images (", paste(filesSuffixList, collapse=", "), ")? At least one valid image needs to be left."), collapse=" ")
    inputRetryPrompt <- "Invalid input. Please enter a valid option number or type one of the provided options."
    toExclude = handleUserInput(filesSuffixList, excludePrompt, inputRetryPrompt, "Check images to exclude", 'C')

    # toExclude <- readline(prompt=excludePrompt)

    if(nchar(toExclude)>0){
      toExclude = sapply(strsplit(toExclude,",")[[1]],trimws)
      backend_message("VARS", 'toExclude', jsonlite::toJSON(toExclude));
      toExclude = c(paste0(as.character(toExclude),".tif"), paste0(as.character(toExclude),"$"))
      ii = sapply(toExclude, function(x) grep(x, rownames(cellCounts)))
      ii = unlist(ii[sapply(ii,length)>0])
      if(!isempty(ii)){
        # print(paste("Excluding",rownames(cellCounts)[ii],"from analysis."), quote = F)
        backend_message("PRNT",functionName,paste("Excluding",rownames(cellCounts)[ii],"from analysis."));
        cellCounts= cellCounts[-ii,, drop=F]
      }
      if(length(ii)==length(f)){
        # stop("At least one valid image needs to be left. Aborting")
        backend_message("ABRT",functionName,"At least one valid image needs to be left. Aborting");
      }
    }

  }
  
  
  ## Calculate cell count per dish
  area2dish = dishSurfaceArea_cm2 / sum(cellCounts[,"area_cm2"])
  dishCount = round(sum(cellCounts[,"areaCount"]) * area2dish)
  dishConfluency = sum(cellCounts[,"dishAreaOccupied"]) * area2dish
  cellSize = median(cellCounts[,"cellSize_um2"],na.rm=T)
  # print(paste("Estimated number of cells in entire flask at",dishCount), quote = F)
  backend_message("PRNT",functionName,paste("Estimated number of cells in entire flask at",dishCount));
  
  if(!is.na(cellCount) && (dishCount/cellCount > 2 || dishCount/cellCount <0.5)){
    # warning(paste0("Automated image analysis deviates from input cell count by more than a factor of 2. CellCount set to the former (",dishCount," cells)"))
    backend_message("NTIF", 'warning', paste0("Automated image analysis deviates from input cell count by more than a factor of 2. CellCount set to the former (",dishCount," cells)"));
  }

  backend_message("RSLT", "cellSize_um2", cellCounts[,"cellSize_um2"]);
  backend_message("RSLT", "dishCount", dishCount);
  backend_message("RSLT", "dishAreaOccupied", dishConfluency);
  backend_message("RSLT", "cellSize", cellSize);
  
  df = data.frame(
    label = c("dishCount", "dishAreaOccupied", "cellSize"),
    value = c(dishCount, dishConfluency, cellSize)
  )
  backend_message("RSLT", "cellCounts", cellCounts);
  # RESULTS_DIR=getEnvSegmentationDir("RESULTS_DIR")        
  # unlink(RESULTS_DIR,recursive=T)
  # dir.create(RESULTS_DIR)
  csvpath = paste0(RESULTS_DIR,"segmentation_results.csv")
  backend_message("RSLT", "csvpath", csvpath);
  write.csv(df, csvpath, row.names=T)
  csvpath2 = paste0(RESULTS_DIR,"segmentation_results2.csv")
  backend_message("RSLT", "csvpath2", csvpath2);
  write.csv(cellCounts, csvpath2, row.names=T)
  csvpath3 = paste0(RESULTS_DIR,"segmentation_results3.csv")
  backend_message("RSLT", "csvpath3", csvpath3);
  write.csv(df, csvpath3, row.names=T)
  return(list(dishCount=dishCount,dishAreaOccupied=dishConfluency, cellSize=cellSize))
}








#          ____    _    ____ _  _______ _   _ ____  ____  _   _ ____ ____  
#         | __ )  / \  / ___| |/ / ____| \ | |  _ \/ ___|| | | | __ ) ___| 
#         |  _ \ / _ \| |   | ' /|  _| |  \| | | | \___ \| | | |  _ \___ \ 
#         | |_) / ___ \ |___| . \| |___| |\  | |_| |___) | |_| | |_) |__) |
#         |____/_/   \_\____|_|\_\_____|_| \_|____/|____/ \___/|____/____/ 
#




source_python_script <- function(script_path) {
  backend_message("INFO", "source_python_script", script_path)
#  functionName<-as.character(match.call()[[1]])
  source_python(script_path)
}

handleUserInput <- function(inputOptions, prompt, retry_prompt, infomessage='NONE', inputType="R") {
  functionName<-as.character(match.call()[[1]])
  while (TRUE)
  {
    user_input <- NULL
    be_verbose <- FALSE
    timeout <- 900
    timeout <- 60
    quit_on_timeout <- TRUE
    quit_on_timeout <- FALSE
    timeout_occured <- 0
    quit_on_noenv <- TRUE
    afia_filename <- "afinputa.txt"
    # afia_filename <- "afir.txt"
    # afiq_filename <- "afinputq.txt"
    afiq_filename <- "afir.txt"
    
    # Check if session is interactive
    if (!inbackend_session) {
      # Print inputOptions
      if (be_verbose) {
        backend_message("INFO", functionName,"Interactive session")
      }
      if(infomessage!='NONE'){
        backend_message("INFO", functionName, infomessage)
      }
      for (i in seq_along(inputOptions)) {
        backend_message("INFO", functionName, paste(i, ": ", inputOptions[i]))
      }
      # Get user input
      user_input <- readline(prompt)
      if (be_verbose) {
        backend_message("INFO", functionName, paste("Terminal user_input: ", user_input))
      }
    } else {
      # Read input from file
      if (be_verbose) {
        backend_message("INFO", functionName, "Non Interactive session")
      }
      txid <- inbackend_session_TXID
      if (is.na(txid) || txid == '') {
        # txid = "TXID_1708137304985"
        if (be_verbose) {
          backend_message("INFO", functionName, "NO TXID IN ENV:")
        }
        if (quit_on_noenv) {
          q(save = "no",
               status = -1,
               runLast = FALSE)
        }
      }
      txid_dir <- getEnvAFIDIR()
      if (is.na(txid_dir) || txid_dir == '') {
        # txid_dir = "/opt/lake/data/cloneid/module02/data/txdir"
        if (be_verbose) {
          backend_message("INFO", functionName, "NO TXDIR IN ENV:")
        }
        if (quit_on_noenv) {
          q(save = "no",
               status = -1,
               runLast = FALSE)
        }
      }
      
      # bckendOutput <- paste(
      #   c(
      #     gsub(":", "", prompt),
      #     paste(gsub(":", "", inputOptions), collapse = "|"),
      #     gsub(":", "", retry_prompt),
      #     gsub(":", "", gsub("\n", "", infomessage))
      #   ),
      #   collapse = "::"
      # )
      Sys.sleep(5);
      cat(paste(
        c(
          "[AFIR]",
          txid,
          gsub(":", "", prompt),
          paste(gsub(":", "", inputOptions), collapse = "|"),
          gsub(":", "", retry_prompt),
          gsub(":", "", infomessage),
          inputType,
          txid
        ),
        collapse = "::"
      ), "\n")
      
      afiq=c()
      afiq$inputType = inputType 
      afiq$prompt = prompt 
      afiq$inputOptions = inputOptions 
      afiq$retry_prompt = retry_prompt 
      afiq$infomessage = infomessage 

      backend_message("AFIQ", 'afiq', jsonlite::toJSON(afiq))

      if (be_verbose) {
        backend_message("INFO", functionName, paste(c(txid_dir, afia_filename), collapse = "::"))
      }
      afia_filepath <- paste(c(txid_dir, afia_filename), collapse = "/")
      afiq_filepath <- paste(c(txid_dir, afiq_filename), collapse = "/")
      if (be_verbose) {
        backend_message("INFO", functionName, paste(c("FILE_WITH_INPUT", afia_filepath), collapse = "::"))
        backend_message("INFO", functionName, paste(c("FILE_WITH_INPUT", afiq_filepath), collapse = "::"))
      }
      start_wait <- Sys.time()
      # until file avail or timeout
      while (TRUE) {
        if (
          # timeout_occured ||
          file.exists(afia_filepath)) {
          # if (timeout_occured) {
          #   user_input <- paste0("#TIMEOUT:", dbTimeFormat(Sys.time()))
          # }else{
            user_input <- readLines(afia_filepath, n = 1)
          # }
          if (length(user_input) > 0) {
            if (be_verbose) {
              backend_message("INFO", functionName, paste(c( "File User Input", user_input), collapse = "="))
            }

            tstp = nowSeconds()

            tryCatch(file.rename(afia_filepath,paste0(afia_filepath, '_', tstp, '.txt')),
                      warning = function(e){ backend_message("WRNG", functionName, e$message) },
                      error = function(e) { backend_message("ERRR", functionName, e$message) },
                      finally = {}
                    )

            if (file.exists(afiq_filepath)) 
            tryCatch(file.rename(afiq_filepath, paste0(afiq_filepath, '_', tstp, '.txt')),
                      warning = function(e){ backend_message("WRNG", functionName, e$message) },
                      error = function(e) { backend_message("ERRR", functionName, e$message) },
                      finally = {}
                    )

            break
          }
        }
        # quit on timeout
        # if (difftime(Sys.time(), start_wait+(timeout_occured*timeout), units = "secs") > timeout) {
        if (difftime(Sys.time(), start_wait, units = "secs") > timeout) {
          if (be_verbose) {
            backend_message("INFO", functionName, "Timeout error: File not found")
          }
          if (quit_on_timeout) {
            q(save = "no", status = -1, runLast = FALSE)
          }else{
            start_wait <- Sys.time()
            backend_message("TIMT", "TIMEOUT", paste0("#TIMEOUT:", dbTimeFormat(start_wait)))
          }
        }
        if (be_verbose) {
          backend_message("INFO", functionName, paste(c("Waiting for", afia_filepath), collapse = " "))
        }
        Sys.sleep(1)
      }
      if (be_verbose) {
        backend_message("INFO", functionName, paste(c("File user_input: ", user_input), collapse = " "))
      }
    }
    
    # Bypass when starts with '#'
    if (startsWith(user_input, '#')) {
      final_input = gsub("#", "", user_input)
      backend_message("INFO", functionName, paste(c( "Final File User Input", final_input), collapse = "="))
      return(final_input)
    }
    
    suppressWarnings(choice <- as.numeric(user_input))
    
    if (be_verbose) {
      backend_message("INFO", functionName, paste(c("choice: ", choice), collapse = " "))
    }
    
    # If the input is a number and within the range of inputOptions
    if (!is.na(choice) && choice >= 1 && choice <= length(inputOptions)) {
      backend_message("INFO", "CHOICE", choice)
      return(choice)
    } else {
      # Check if the input matches any option
      matched_option <- which(tolower(inputOptions) == tolower(user_input))
      if (length(matched_option) > 0) {
        backend_message("INFO", "MATCHED", matched_option)
        return(matched_option)
      } else {
        backend_message("INFO", functionName, retry_prompt)
      }
    }
  }
}

backend_message <- function(Level, k, v){
    if ((is.null(Level) || length(Level)==0 )){
      cat("NO Level", "\n")
      q();
    }
  functionName<-as.character(match.call()[[1]])
  if(inbackend_session){
    txid <- inbackend_session_TXID
    if ((is.null(txid) || length(txid)==0 )){
      cat("NO TXID", "\n")
      q();
    }
    # tx1 = Sys.time()
    tx2 <- dbTimeFormat(Sys.time())

# [ABRT]
# [AFIQ]
# [AFIR]
# [DONE]
# [INFO]
# [JSON]
# [MESG]
# [MSQL]
# [NTIF]
# [PRNT]
# [QUIT]
# [RSLT]
# [VARS]
# [WRNG]

    if (Level=="TIMT" || Level=="ABRT" || Level=="AFIQ" || Level=="AFIR" || Level=="DONE" || Level=="INFO" || Level=="JSON" || Level=="MESG" || Level=="MSQL" || Level=="NTIF" || Level=="PRNT" || Level=="QUIT" || Level=="RSLT" || Level=="VARS" || Level=="WRNG"){
      cat(paste(
          c(
            paste0('[',Level,']'),
            as.character(txid),
            as.character(tx2),
            paste(c(k, v), collapse = "|"),
            as.character(txid) 
          ),
          collapse = "::"
        ), "\n")
      if (Level=="ABRT"){
        Sys.sleep(10)
        q()
      }
      Sys.sleep(0.2)
    }else{
      print(Level)
      Sys.sleep(100)
    }
    # if (!(is.null(v) || length(v)==0 )){
    #   cat(
    #       paste(
    #         c(
    #           as.character(txid),
    #           as.character(tx2),
    #           paste0('[',Level,']'),
    #           paste(c(k, v), collapse = "|"),
    #           as.character(txid) 
    #         ),
    #         collapse = "::"
    #       ),
    #       "\n"
    #     )
    # }else{
    #   cat(
    #       paste(
    #         c(
    #           as.character(txid),
    #           as.character(tx2),
    #           paste0('[',Level,']'),
    #           k,
    #           as.character(txid),
    #         ),
    #         collapse = "::"
    #       ),
    #       "\n"
    #     )
    # }
    # Sys.sleep(3)
  }else{
    if (!(is.null(v) || length(v)==0)){
      if(Level=="INFO"){
        cat(paste(c(v,"\n")))
        # print(v, quote=F)
      }
      if(Level=="PRNT"){
        cat(paste(c(v,"\n")))
        # print(v, quote=F)
      }
      if(Level=="NTIF"){
        cat(paste(c(v,"\n")))
        # print(v, quote=F)
      }
      if(Level=="WRNG"){
        warning(v, immediate=T)
      }
      # cat(paste(c(v,"\n")))
      # return
    }
  }
}

getEnvSegmentationDir <- function(dir){
  functionName<-as.character(match.call()[[1]])
  tmp=Sys.getenv(dir) 
  k=paste(c("GET", dir), collapse = " ")
  backend_message("INFO",k,tmp)
  return(tmp)
}
getEnvAFIDIR <- function(){
  tmp=Sys.getenv("TXID_DIR_AFI") 
  backend_message("INFO", "GET TXID_DIR_AFI", tmp)
  return(tmp)
}
getEnvTXID <- function(){
  tmp=Sys.getenv("TXID") 
  inbackend_session_TXID <<- tmp
  return(tmp)
}
getEnvRunningInBackend <- function(){
  tmp=Sys.getenv("RUNNINGINBACKEND") 
  inbackend_session <<- (tmp=="TRUE")
  return(tmp=="TRUE")
}

nowSeconds <- function(stmt, mess=NULL){
  return(as.integer(unclass(as.POSIXct(Sys.time()))))
}

dbConnect <- function(sSQLHOST, sSQLPORT, sSQLUSER, sSQLPSWD, sSQLSCHM){
  functionName<-as.character(match.call()[[1]])
  backend_message("INFO", "SQLPARAMETERS", paste(c(sSQLHOST, sSQLPORT, sSQLUSER, sSQLPSWD, sSQLSCHM), collapse = ":"));
  mysql_setup <- setupCLONEID(
    host = sSQLHOST,
    port = sSQLPORT,
    user = sSQLUSER,
    password = sSQLPSWD,
    database = sSQLSCHM,
    schemaScript = 'CLONEID_schema.sql'
  )
  backend_message("INFO", "SQLRESULT", mysql_setup);
}
dbFetchResults <- function(stmt, mess=NULL){
  results <- dbLoadResults(stmt,mess)
  dataframe <- dbFetch(results, n=-1)
  # backend_message("MSQL",mess,dataframe)
  dbClearResult(results)
  return(dataframe)
}
dbLoadResults <- function(stmt, mess){
  if(is.null(mydb)){
    mydb = connect2DB()
  }
  backend_message("MSQL",mess,stmt)
  # results<-suppressWarnings(suppressMessages(dbSendQuery(mydb,stmt)))
  # results <- NULL
  # tryCatch({
      results<-dbSendQuery(mydb,stmt)
      return(results)
    # },
    # warning = function(e){ backend_message("WRNG", stmt, e$message) },
    # error = function(e) { backend_message("ERRR", stmt, e$message) },
    # finally = {return(results)}
  # )
}
dbFetchUser <- function(){
  x = dbFetchResults("SELECT user()")
  return(x[,1])
}
dbTimeFormat <- function(x){
  return(format(as.POSIXlt(as.numeric(x)),'%Y-%m-%d %H:%M:%S'))
}










#options(warn=0,error=quote({dump.frames(to.file=TRUE); q()}))

# SET TESTING
IVUTEST_CHECKRESULT=FALSE
IVUTEST_HANDLEINPUT=FALSE
IVUTEST_FORCESETENV=FALSE
IVUTEST_USEFAKEARGS=FALSE
#


if(IVUTEST_FORCESETENV==TRUE || Sys.getenv("IVUTEST_FORCESETENV")=="TRUE"){
  MODULE2_LINEAGE_TESTING_DIR='/opt/lake/data/cloneid/module02/data/test/cellpose/lineage26/'
  Sys.setenv( CELLSEGMENTATIONS_INDIR=as.character(paste0(c(MODULE2_LINEAGE_TESTING_DIR, 'input'), collapse='')) )
  Sys.setenv( CELLSEGMENTATIONS_OUTDIR=paste0(c(MODULE2_LINEAGE_TESTING_DIR, "output/"), collapse='') )
  Sys.setenv( TMP_DIR=paste0(c(MODULE2_LINEAGE_TESTING_DIR, "tmp/"), collapse='') )
  Sys.setenv( RESULTS_DIR=paste0(c(MODULE2_LINEAGE_TESTING_DIR, "results/"), collapse='') )
  Sys.setenv( TXID=nowSeconds() )
  Sys.setenv( TXID_DIR_AFI=paste0(c(MODULE2_LINEAGE_TESTING_DIR, "backendinput/"), collapse='') )
  Sys.setenv( RUNNINGINBACKEND="TRUE" )
}

dbX <- TRUE
mydb <-  NULL 
alreadyProcessed <- FALSE
discardPreviousResults <- !alreadyProcessed
inbackend_session_TXID <- getEnvTXID() 
inbackend_session <- getEnvRunningInBackend() 
backend_message("INFO", "GET TXID", inbackend_session_TXID)
backend_message("INFO", "GET RUNNINGINBACKEND", inbackend_session)

TEST_handleUserInput <- function(inputOptions, inputPrompt, inputRetryPrompt, inputMessage='', type='R') {
  # Usage
  # inputOptions <- c("Option A", "Option B", "Option C")
  # prompt <- "Enter option number or type your own: "
  # retry_prompt <- "Invalid input. Please enter a valid option number or type one of the provided inputOptions."
  # TEST_handleUserInput(inputOptions, prompt, retry_prompt)
  inputSelectedOption <- handleUserInput(inputOptions, inputPrompt, inputRetryPrompt, inputMessage, type)
  backend_message("INFO", "selected_option", inputSelectedOption)
  backend_message("INFO", "You selected", ifelse(startsWith(as.character(inputSelectedOption), '#'), inputSelectedOption, inputOptions[inputSelectedOption]))
  backend_message("INFO", "You selected", jsonlite::toJSON(c( 'x', ifelse(startsWith(as.character(inputSelectedOption), '#'), inputSelectedOption, inputOptions[inputSelectedOption]))))
  # TEST and quit
  Sys.sleep(5)
  # q()
}
IVUTEST_HANDLEINPUT=!TRUE
if(IVUTEST_HANDLEINPUT==TRUE || Sys.getenv("IVUTEST_HANDLEINPUT")=="TRUE"){
  
  # Usage
  inputMessage = paste(
  c(
    "Fer (Fe) - L'élément le plus communément associé à des propriétés magnétiques.",
  "Cobalt (Co) - Présente une forte magnétisation, notamment dans ses alliages.",
  "Nickel (Ni) - Affiche également des propriétés magnétiques significatives, en particulier dans certaines conditions.",
  "Gadolinium (Gd) - Un lanthanide qui montre une forte susceptibilité magnétique.",
  "Néodyme (Nd) - Utilisé dans la fabrication d'aimants puissants, il possède des propriétés magnétiques remarquables."
  ),
  sep="\n")
  inputOptions <- c("Fer (Fe)", "Cobalt (Co)", "Nickel (Ni)", "Gadolinium (Gd)", "Néodyme (Nd)")
  inputPrompt <- "Select an option : "
  inputRetryPrompt <- "Invalid input. Please enter a valid option number or type one of the provided options."
  TEST_handleUserInput(inputOptions, inputPrompt, inputRetryPrompt, inputMessage)


  # Usage
  inputMessage = paste(
  c(
  "A Fer (Fe) - L'élément le plus communément associé à des propriétés magnétiques.",
  "B Cobalt (Co) - Présente une forte magnétisation, notamment dans ses alliages.",
  "C Nickel (Ni) - Affiche également des propriétés magnétiques significatives, en particulier dans certaines conditions."
  ),
  sep="\n"
  )
  inputOptions <- c("Option A", "Option B", "Option C")
  inputPrompt <- "Enter option number or type your own:"
  inputRetryPrompt <- "Invalid input. Please enter a valid option number or type one of the provided options."
  TEST_handleUserInput(inputOptions, inputPrompt, inputRetryPrompt, inputMessage)


  filesSuffixList=c("a","b","c","d")
  excludePrompt=paste(c("Exclude any images (", paste(filesSuffixList, collapse=", "), ")? At least one valid image needs to be left."), collapse=" ")
  inputRetryPrompt <- "Invalid input. Please enter a valid option number or type one of the provided options."
  toExclude = handleUserInput(filesSuffixList, excludePrompt, inputRetryPrompt, "Check images to exclude", 'C')


  # Usage
  inputMessage = paste(
  c(
    "Yes Fer (Fe) - L'élément le plus communément associé à des propriétés magnétiques.",
    "No Cobalt (Co) - Présente une forte magnétisation, notamment dans ses alliages."
  ),
  sep="\n"
  )
  inputOptions <- c("Yes", "No")
  inputPrompt <- "Select option:"
  inputRetryPrompt <- "Invalid input. Please enter a valid option number or type one of the provided options."
  TEST_handleUserInput(inputOptions, inputPrompt, inputRetryPrompt, inputMessage)



  # Usage
  inputMessage = paste(
  c(  "AAAAAAAAAAAAAAAAAAAAAAAA",
    "BBBBBBBBBBBBBBBBBBBBBBBB",
    "CCCCCCCCCCCCCCCCCCCCCCCC",
  ),  sep="\n")
  inputOptions <- c("A", "B", "C")
  inputPrompt <- "Select:"
  inputRetryPrompt <- "Invalid input. Please retry"
  TEST_handleUserInput(inputOptions, inputPrompt, inputRetryPrompt, inputMessage)


  q()
}


# [AFIR]
# [INFO]
# [JSON]
# [MESG]
# [NTIF]
# [QUIT]
# [VARS]


IVUTEST_NOTIFYTYPES=FALSE

# if(FALSE){
if(IVUTEST_NOTIFYTYPES==TRUE || Sys.getenv("IVUTEST_NOTIFYTYPES")=="TRUE"){
  functionName="test"
  r=c(1,2,3)
  mess="SQL STATEMENT"
  stmt="SELECT * FROM test;"
  xmessage="ERROR"
# backend_message("ABRT", functionName, "At least one valid image needs to be left. Aborting");
# backend_message("DONE", "result", r);
# backend_message("ERRR", stmt, message)
backend_message("INFO", "ARGS", paste(c(functionName, 1,2,3, collapse = "::")))
  # Sys.sleep(3)
backend_message("JSON", "result", jsonlite::toJSON(c(0,1,2,3,4,5,6,7,8,9)));
  # Sys.sleep(3)
backend_message("MESG", 'info', "DB Access Passaging"); 
  # Sys.sleep(3)
backend_message("MSQL", mess, stmt)
  # Sys.sleep(3)
backend_message("NTIF", 'error', 'error');
  # Sys.sleep(3)
backend_message("NTIF", 'info', 'info');
  # Sys.sleep(3)
backend_message("NTIF", 'info', paste("Cell count error predicted as negligible for",4));
  # Sys.sleep(3)
backend_message("NTIF", 'info', paste("Copying media information from parent: media set to",9));
  # Sys.sleep(3)
backend_message("NTIF", 'success', 'success');
  # Sys.sleep(3)
backend_message("NTIF", 'warning', 'warning');
  # Sys.sleep(3)
backend_message("NTIF", 'warning', "Low image quality predicted for at least one image");
  # Sys.sleep(3)
backend_message("PRNT", functionName, paste("Estimated number of cells in entire flask at",99));
  # Sys.sleep(3)
backend_message("RSLT", "cellSize_um2", jsonlite::toJSON(c(0,1,2,3,4,5,6,7,8,9)));
  # Sys.sleep(3)
backend_message("RSLT", "csvpath4", functionName);
  # Sys.sleep(3)
backend_message("VARS", 'excludeOption', TRUE);
  # Sys.sleep(3)
backend_message("WRNG", stmt, xmessage)
  # Sys.sleep(3)
backend_message("QUIT", "IVUTEST_NOTIFYTYPES", IVUTEST_NOTIFYTYPES);
  # Sys.sleep(3)

#   Sys.sleep(3)
#   q()
# }
# if(IVUTEST_NOTIFYTYPES==TRUE || Sys.getenv("IVUTEST_NOTIFYTYPES")=="TRUE"){
  # backend_message("NTIF", 'none', 'none');
  # Sys.sleep(10)
  # backend_message("NTIF", 'clear', 'clear');
  # Sys.sleep(10)
  backend_message("JSON", "result", jsonlite::toJSON(c(0,1,2,3,4,5,6,7,8,9)));
  # Sys.sleep(3)
  backend_message("NTIF", 'info', 'info');
  # Sys.sleep(3)
  backend_message("NTIF", 'error', 'error');
  # Sys.sleep(3)
  backend_message("NTIF", 'warning', 'warning');
  # Sys.sleep(3)
  backend_message("NTIF", 'success', 'success');
  # Sys.sleep(3)
  backend_message("JSON", "result", jsonlite::toJSON(c(9,8,7,6,5,4,3,2,1,0)));
  # Sys.sleep(3)
  backend_message("QUIT", "IVUTEST_NOTIFYTYPES", IVUTEST_NOTIFYTYPES);
  # Sys.sleep(0)
  q()
}


library(cloneid)
library(RMySQL)
library(matlab)
library(reticulate)
library(jsonlite)

#suppressWarnings(suppressMessages( library(cloneid) ))
#suppressWarnings(suppressMessages( library(RMySQL) ))
#suppressWarnings(suppressMessages( library(matlab) ))
#suppressWarnings(suppressMessages( library(reticulate) ))
#suppressWarnings(suppressMessages( library(jsonlite) ))

args <- commandArgs(trailingOnly = TRUE)
if(length(args)){
  backend_message("INFO", "arguments", paste(args, collapse = "::"))
}
if (length(args) >= 12) {
  event <- args[1]
  id <- args[2]
  from <- args[3]
  cellCount <- args[4]
  tx <- args[5]
  flask <- args[6]
  media <- args[7]
  # SQLHOST <- args[8]
  # SQLPORT <- args[9]
  # SQLUSER <- args[10]
  # SQLPSWD <- args[11]
  # SQLSCHM <- args[12]
  dbConnect(args[8], args[9], args[10], args[11], args[12])
  
  datadir <- args[13]
  imagesets <- args[14]
  imageset <- args[15]
  transactionId <- args[16]
  
  if (is.na(flask) || is.null(flask)){
    flask = NULL
  }

  if (is.na(media) || is.null(media)){
    media = NULL
  }
   
  if (media == 0){
    media = NULL
  }

  if (media == "NULL"){
    media = NULL
  }
   
  if (cellCount == "NULL") {
    cellCount = NaN
  }
  
  if (cellCount == "NaN") {
    cellCount = NaN
  }
  
  if (cellCount == "nan") {
    cellCount = NaN
  }
  
  if (cellCount == "N/A") {
    cellCount = NaN
  }
  
  if (cellCount == "n/a") {
    cellCount = NaN
  }
  
  if (cellCount == "NA") {
    cellCount = NaN
  }
  
  if (cellCount == "na") {
    cellCount = NaN
  }
  
  excludeOption = F
  preprocessing = T
  param = NULL

  backend_message("INFO", "arguments", paste(args, collapse = ":"))
  
} else {
  # backend_message("INFO", "Usage", "Rscript script.R event id from cellCount tx flask media transactionid SQLHOST SQLPORT SQLUSER SQLPSWD SQLSCHM datadir imagesets")
 if(IVUTEST_USEFAKEARGS==TRUE || Sys.getenv("IVUTEST_USEFAKEARGS")=="TRUE"){
  event = "harvest" # "seeding"
  id = "HGC-27_A1_seedTP48"
  from = "HGC-27_A1_seed"
  cellCount = NaN
  tx = Sys.time()
  flask = 1
  media = 43
  imageset <- "cellpose-test-transaction-id"
  datadir <- "/opt/lake/data/cloneid/module02/data/test/cellpose/lineage26"
  imagesets <- "uncertifiedUsers"
  transactionId <- nowSeconds()
  dbConnect('192.168.1.4','13307','root','xxxxx','CLONEID')
  excludeOption = F
  preprocessing = T
  param = NULL
 }else{
  q()
 }
}
if (tx==0) {
  tx = Sys.time()
}

TMP_DIR=''
CELLSEGMENTATIONS_OUTDIR=''
CELLSEGMENTATIONS_INDIR=''
RESULTS_DIR=''

if (datadir!='' && imagesets!='' && imageset!=''){
  TRANSACTION_DIR = normalizePath(paste0(datadir, "/", imagesets, "/", imageset))
  TMP_DIR = normalizePath(paste0(TRANSACTION_DIR, "/tmp"))
  CELLSEGMENTATIONS_OUTDIR = paste0(normalizePath(paste0(TRANSACTION_DIR, "/output")), "/")
  CELLSEGMENTATIONS_INDIR = paste0(normalizePath(paste0(TRANSACTION_DIR, "/input")), "/")
  RESULTS_DIR = paste0(normalizePath(paste0(TRANSACTION_DIR, "/results")), "/")
}else{
  TMP_DIR=getEnvSegmentationDir("TMP_DIR")
  CELLSEGMENTATIONS_OUTDIR=getEnvSegmentationDir("CELLSEGMENTATIONS_OUTDIR")
  CELLSEGMENTATIONS_INDIR=getEnvSegmentationDir("CELLSEGMENTATIONS_INDIR")
  RESULTS_DIR=getEnvSegmentationDir("RESULTS_DIR")        
}

tx <- dbTimeFormat(tx)

backend_message("INFO", "arguments", paste(c(event, id, from, cellCount, tx, flask, media, excludeOption, preprocessing, param), collapse = "::"));
backend_message("INFO", 'RUNNINGINBACKEND', Sys.getenv("RUNNINGINBACKEND") )
backend_message("INFO", 'TXID', Sys.getenv("TXID") )
backend_message("INFO", 'TXID_DIR_AFI', Sys.getenv("TXID_DIR_AFI") )

backend_message("INFO", 'CELLSEGMENTATIONS_INDIR', CELLSEGMENTATIONS_INDIR )
suppressWarnings(dir.create(CELLSEGMENTATIONS_INDIR))
backend_message("INFO", 'CELLSEGMENTATIONS_OUTDIR', CELLSEGMENTATIONS_OUTDIR )
suppressWarnings(dir.create(CELLSEGMENTATIONS_OUTDIR))
backend_message("INFO", 'TMP_DIR', TMP_DIR )
suppressWarnings(dir.create(TMP_DIR))
backend_message("INFO", 'RESULTS_DIR', RESULTS_DIR )
dir.create(RESULTS_DIR)
#suppressWarnings(dir.create(RESULTS_DIR))

if (inbackend_session){
#  backend_message("INFO", "use_condaenv", c('',use_condaenv(condaenv = "cellpose", conda = "/root/miniconda3/bin/conda")))
#  backend_message("INFO", "conda_list", conda_list())
}

  
backend_message("INFO", "MEDIA", media )

# Launch Seed or Harvest 
if(event == "seeding"){
  r <- seed(id, from, cellCount, flask, format(as.POSIXlt(Sys.time()),'%Y-%m-%d %H:%M:%S'), media); 
} else if(event == "harvest"){
  # print(media)
  # if(media==NULL){
    # backend_message("INFO", "harvest", c(id, from, cellCount, format(as.POSIXlt(Sys.time()),'%Y-%m-%d %H:%M:%S'), "media==NULL") )
  # }else{
    backend_message("INFO", "harvest", c(id, from, cellCount, format(as.POSIXlt(Sys.time()),'%Y-%m-%d %H:%M:%S'), media) )
  # }
  r <- harvest(id, from, cellCount, format(as.POSIXlt(Sys.time()),'%Y-%m-%d %H:%M:%S'), media); 
}


# backend_message("DONE", "result", names(r));
# backend_message("DONE", "result", r);
backend_message("JSON", "finalresult", jsonlite::toJSON(r));

csvpath4 = paste0(RESULTS_DIR,"final_results.csv")
backend_message("RSLT", "csvpath4", csvpath4);
write.csv(r, csvpath4, row.names=T)

Sys.sleep(10)
q()
# backend_message("DONE", "warnings", warnings())


# Rscript --vanilla /opt/lake/data/cloneid/module02/data/scripts/IVU5.R harvest HGC-27_A1_seedTP48 HGC-27_A1_seed N/A 1809491919 2 43
#                                                                       sql2 3306 root xxxxx CLONEID
#                                                                       /opt/lake/data/cloneid/module02/data/files/cellpose/ 
#                                                                       imagesets 
#                                                                       e98bd7a0359f7dbaf5f9337bedff4d9ad53abd6a812a10b4b9a42557f272d3ddbd20db0c83fe9201f72105a10d5e85067eddd55a0ac30f1ce808271311169722


# AVAIL TESTING
# export IVUTEST_CHECKRESULT=TRUE
# export IVUTEST_HANDLEINPUT=TRUE
# export IVUTEST_FORCESETENV=TRUE
# export IVUTEST_USEFAKEARGS=TRUE
# export IVUTEST_NOTIFYTYPES=TRUE

