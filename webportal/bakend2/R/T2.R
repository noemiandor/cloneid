# SET TESTING
IVUTEST_CHECKRESULT=FALSE
IVUTEST_HANDLEINPUT=FALSE
IVUTEST_FORCESETENV=FALSE
IVUTEST_USEFAKEARGS=FALSE
#

IVUTEST_USEFAKEARGS<-TRUE
















#          ____    _    ____ _  _______ _   _ ____  ____  _   _ ____ ____  
#         | __ )  / \  / ___| |/ / ____| \ | |  _ \/ ___|| | | | __ ) ___| 
#         |  _ \ / _ \| |   | ' /|  _| |  \| | | | \___ \| | | |  _ \___ \ 
#         | |_) / ___ \ |___| . \| |___| |\  | |_| |___) | |_| | |_) |__) |
#         |____/_/   \_\____|_|\_\_____|_| \_|____/|____/ \___/|____/____/ 
#

# TRANSACTION_DIR 			= createDirIfnotExists('TRANSACTION_DIR',					c(datadir, imagesets, imageset))
# TMP_DIR						= createDirIfnotExists('TMP_DIR',							c(TRANSACTION_DIR, "tmp"))
# CELLSEGMENTATIONS_OUTDIR	= createDirIfnotExists('CELLSEGMENTATIONS_OUTDIR',		c(TRANSACTION_DIR, "output"))
# CELLSEGMENTATIONS_INDIR		= createDirIfnotExists('CELLSEGMENTATIONS_INDIR',			c(TRANSACTION_DIR, "input"))
# RESULTS_DIR					= createDirIfnotExists('RESULTS_DIR',						c(TRANSACTION_DIR, "results"))
#
# DETECTIONRESULTS_OUTDIR		= createDirIfnotExists('DETECTIONRESULTS_OUTDIR',			c(CELLSEGMENTATIONS_OUTDIR, "DetectionResults"))
# MORPHOLOGYPERSPECTIVE_OUTDIR=createDirIfnotExists('MORPHOLOGYPERSPECTIVE_OUTDIR',	c(TRANSACTION_DIR, "morphologyPerspective"))


createDirIfnotExists <- function(name, dir){
  functionName<-as.character(match.call()[[1]])
  # np<-normalizePath(dir,mustWork=TRUE)
  np<-normalizePath(paste0(dir, collapse = '/'))
  if(!dir.exists(np)){
	  dir.create(np, showWarnings = TRUE, recursive = TRUE, mode = "0777")
  }
  backend_message("INFO", functionName, paste(name,np));
  assign(name, np, envir = .GlobalEnv)
}


source_python_script <- function(script_path) {
  functionName<-as.character(match.call()[[1]])
  backend_message("INFO",functionName,script_path)
  reticulate::source_python(script_path)
}

handleUserInput <- function(inputOptions, prompt, retry_prompt, infomessage='NONE', inputType="R") {
  functionName<-as.character(match.call()[[1]])
  while (TRUE)
  {
    user_input <- NULL
    be_verbose <- FALSE
    timeout <- 900
    quit_on_timeout <- TRUE
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

      # backend_message("AFIQ", 'afiq', jsonlite::toJSON(c(inputType, prompt, inputOptions, retry_prompt, infomessage)))
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
        if (file.exists(afia_filepath)) {
          user_input <- readLines(afia_filepath, n = 1)
          if (length(user_input) > 0) {
            if (be_verbose) {
              backend_message("INFO", functionName, paste(c( "File User Input", user_input), collapse = "="))
            }

            # if (FALSE)
            # tryCatch(file.remove(afia_filepath),
            #           warning = function(e){ backend_message("WRNG", functionName, e$message) },
            #           error = function(e) { backend_message("ERRR", functionName, e$message) },
            #           finally = {}
            #         )


            # tryCatch(file.remove(afiq_filepath),
            #           warning = function(e){ backend_message("WRNG", functionName, e$message) },
            #           error = function(e) { backend_message("ERRR", functionName, e$message) },
            #           finally = {}
            #         )

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
        if (difftime(Sys.time(), start_wait, units = "secs") > timeout) {
          if (be_verbose) {
            backend_message("INFO", functionName, "Timeout error: File not found")
          }
          if (quit_on_timeout) {
            q(save = "no", status = -1, runLast = FALSE)
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
      return(choice)
    } else {
      # Check if the input matches any option
      matched_option <- which(tolower(inputOptions) == tolower(user_input))
      if (length(matched_option) > 0) {
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

    if (Level=="ABRT" || Level=="AFIQ" || Level=="AFIR" || Level=="DONE" || Level=="INFO" || Level=="JSON" || Level=="MESG" || Level=="MSQL" || Level=="NTIF" || Level=="PRNT" || Level=="QUIT" || Level=="RSLT" || Level=="VARS" || Level=="WRNG"){
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
      # return
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
        return
        # print(v, quote=F)
      }
      if(Level=="PRNT"){
        cat(paste(c(v,"\n")))
        return
        # print(v, quote=F)
      }
      if(Level=="NTIF"){
        cat(paste(c(v,"\n")))
        return
        # print(v, quote=F)
      }
      if(Level=="WRNG"){
        warning(v, immediate=T)
        return
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


options(warn=0,error=quote({dump.frames(to.file=TRUE); q()}))


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
IVUTEST_NOTIFYTYPES=FALSE
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

suppressWarnings(suppressMessages( library(cloneid) ))
suppressWarnings(suppressMessages( library(RMySQL) ))
suppressWarnings(suppressMessages( library(matlab) ))
suppressWarnings(suppressMessages( library(reticulate) ))
suppressWarnings(suppressMessages( library(jsonlite) ))

args <- commandArgs(trailingOnly = TRUE)

if(length(args)){
  backend_message("INFO", "arguments", paste(args, collapse = "::"))
}
IVUTEST_USEFAKEARGS=TRUE 
if (length(args) >= 12)
{
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
	# CELLPOS_DIR, 'imagesets', imageset,
	datadir <- args[13]
	imagesets <- args[14]
	imageset <- args[15]
  transactionId <- args[16]
	# backend_message("INFO", "arg16", args[16])
	backend_message("INFO", "arg16", transactionId)

	# if (flask == "NULL") {
	# flask = NULL
	# }

	# if (cellCount == "NaN") {
	# cellCount = NaN
	# }

	# if (cellCount == "nan") {
	# cellCount = NaN
	# }

	# if (cellCount == "N/A") {
	# cellCount = NaN
	# }

	# if (cellCount == "n/a") {
	# cellCount = NaN
	# }

	# if (cellCount == "NA") {
	# cellCount = NaN
	# }

	# if (cellCount == "na") {
	# cellCount = NaN
	# }

	excludeOption = F
	preprocessing = T
	param = NULL

	backend_message("INFO", "arguments", paste(args, collapse = ":"))

} else {
  backend_message("INFO", "Usage", "Rscript script.R event id from cellCount tx flask media imageset SQLHOST SQLPORT SQLUSER SQLPSWD SQLSCHM datadir imagesets")
  if(IVUTEST_USEFAKEARGS==TRUE || Sys.getenv("IVUTEST_USEFAKEARGS")=="TRUE"){
  event = "harvest" # "seeding"
  id = "HGC-27_A1_seedTP48"
  from = "HGC-27_A1_seed"
  cellCount = NaN
  tx = Sys.time()
  flask = 1
  media = 43
  # /opt/lake/data/cloneid/module02/data/files/cellpose/imagesets/d6c06525aaa5739c27cb506436c3a26652364a3b746414873e1d521b901d1e32ee05a9a850fd62dd84d4754528424fbd2f9f2f8b21224d82abe69511831a4023 
  imageset <- "d6c06525aaa5739c27cb506436c3a26652364a3b746414873e1d521b901d1e32ee05a9a850fd62dd84d4754528424fbd2f9f2f8b21224d82abe69511831a4023"
  datadir <- "/opt/lake/data/cloneid/module02/data/files/cellpose"
  imagesets <- 'imagesets'
  # transactionId <- nowSeconds()
  # transactionId <- 1710653881
  transactionId <- 1710653874754
  # transactionId <- as.integer(1710653874754/1000)
  # transactionId <- as.numeric(1710653874754/1000)
  # transactionId <- 2147483647
  # dbConnect('192.168.1.14','13307','root','xxxxx','CLONEID')
  dbConnect('sql2','3306','root','xxxxx','CLONEID')
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
    # TRANSACTION_DIR = normalizePath(paste0(datadir, "/", imagesets, "/", imageset))
    # TMP_DIR = normalizePath(paste0(TRANSACTION_DIR, "/tmp"))
    # CELLSEGMENTATIONS_OUTDIR = paste0(normalizePath(paste0(TRANSACTION_DIR, "/output")), "/")
    # CELLSEGMENTATIONS_INDIR = paste0(normalizePath(paste0(TRANSACTION_DIR, "/input")), "/")
    # RESULTS_DIR = paste0(normalizePath(paste0(TRANSACTION_DIR, "/results")), "/")

  # TRANSACTION_DIR					= createDirIfnotExists('TRANSACTION_DIR',			c(datadir, imagesets, imageset))
  # TMP_DIR							= createDirIfnotExists('TMP_DIR',					c(TRANSACTION_DIR, "tmp"))
  # CELLSEGMENTATIONS_OUTDIR			= createDirIfnotExists('CELLSEGMENTATIONS_OUTDIR',	c(TRANSACTION_DIR, "output"))
  # CELLSEGMENTATIONS_INDIR			= createDirIfnotExists('CELLSEGMENTATIONS_INDIR',	c(TRANSACTION_DIR, "input"))
  # RESULTS_DIR						= createDirIfnotExists('RESULTS_DIR',				c(TRANSACTION_DIR, "results"))

	createDirIfnotExists('TRANSACTION_DIR',					c(datadir, imagesets, imageset))
	createDirIfnotExists('TMP_DIR',							c(TRANSACTION_DIR, "tmp"))
	createDirIfnotExists('CELLSEGMENTATIONS_OUTDIR',		c(TRANSACTION_DIR, "output"))
	createDirIfnotExists('CELLSEGMENTATIONS_INDIR',			c(TRANSACTION_DIR, "input"))
	createDirIfnotExists('RESULTS_DIR',						c(TRANSACTION_DIR, "results"))
	
	createDirIfnotExists('DETECTIONRESULTS_OUTDIR',			c(CELLSEGMENTATIONS_OUTDIR, "DetectionResults"))
	createDirIfnotExists('MORPHOLOGYPERSPECTIVE_OUTDIR',	c(TRANSACTION_DIR, "morphologyPerspective"))
	
		
}else{
    # TMP_DIR=getEnvSegmentationDir("TMP_DIR")
    # CELLSEGMENTATIONS_OUTDIR=getEnvSegmentationDir("CELLSEGMENTATIONS_OUTDIR")
    # CELLSEGMENTATIONS_INDIR=getEnvSegmentationDir("CELLSEGMENTATIONS_INDIR")
    # RESULTS_DIR=getEnvSegmentationDir("RESULTS_DIR")
	
	createDirIfnotExists('TRANSACTION_DIR',					getEnvSegmentationDir("TRANSACTION_DIR"))
	createDirIfnotExists('TMP_DIR',							getEnvSegmentationDir("TMP_DIR"))
	createDirIfnotExists('CELLSEGMENTATIONS_OUTDIR',		getEnvSegmentationDir("CELLSEGMENTATIONS_OUTDIR"))
	createDirIfnotExists('CELLSEGMENTATIONS_INDIR',			getEnvSegmentationDir("CELLSEGMENTATIONS_INDIR"))
	createDirIfnotExists('RESULTS_DIR',						getEnvSegmentationDir("RESULTS_DIR"))
	createDirIfnotExists('DETECTIONRESULTS_OUTDIR',			getEnvSegmentationDir("DETECTIONRESULTS_OUTDIR"))
	createDirIfnotExists('MORPHOLOGYPERSPECTIVE_OUTDIR',	getEnvSegmentationDir("MORPHOLOGYPERSPECTIVE_OUTDIR"))
	
}

tx <- dbTimeFormat(tx)

backend_message("INFO", "arguments", paste(c(event, id, from, cellCount, tx, flask, media, excludeOption, preprocessing, param), collapse = "::"));
backend_message("INFO", 'RUNNINGINBACKEND', Sys.getenv("RUNNINGINBACKEND") )
backend_message("INFO", 'TXID', Sys.getenv("TXID") )
backend_message("INFO", 'TXID_DIR_AFI', Sys.getenv("TXID_DIR_AFI") )

if (inbackend_session){
  backend_message("INFO", "use_condaenv", c('',use_condaenv(condaenv = "cellpose", conda = "/root/miniconda3/bin/conda")))
  backend_message("INFO", "conda_list", conda_list())
}

finalresult=c("This", "is", "an", "example", "result", "set")

##############################################################################################################################################################################





















#################################################################### cellSegmentation:
#   input:  /root/containerdir/CLONEID/cellpose4/CellSegmentations/input
#   output: /root/containerdir/CLONEID/cellpose4/CellSegmentations/output/
#   tmp:    /root/containerdir/CLONEID/cellpose4/tmp/

viewPerspectiveX<-function(spstatsFile, whichP, suffix=".sps.cbs", xy=NULL){
  #   library("rJava")
  #   library(matlab)
  # NUMRES=getNumRes()
  
  
  backend_message("INFO", 'viewPerspectiveX', paste(spstatsFile, '=', whichP) )
  
  
  NUMRES=7
  spstatsFile = gsub(suffix, "", spstatsFile, fixed = T);
  clonesDIR=gsub("~",Sys.getenv("HOME"), fileparts(spstatsFile)$pathstr)
  spstatsFile=gsub("~",Sys.getenv("HOME"),spstatsFile)
  
  sampleName=fileparts(spstatsFile)$name
  clonesIn=paste(clonesDIR,filesep,sampleName,suffix,sep="")
  if(!R.utils::isAbsolutePath(clonesDIR)){
    clonesIn=paste(getwd(),filesep,clonesIn,sep="")
  }
  
  ####################################################################
  ####View clonal composition of a sample from a given perspective###
  # gP=J("core.utils.Perspectives")$GenomePerspective
  # eP=J("core.utils.Perspectives")$ExomePerspective
  # tP=J("core.utils.Perspectives")$TranscriptomePerspective
  # kP=J("core.utils.Perspectives")$KaryotypePerspective
  mP=J("core.utils.Perspectives")$MorphologyPerspective
  if(!file.exists(clonesIn)){
    # print(paste("Clonal composition input does not exists at:",clonesIn,". Run clonal decomposition algorithm first."))
    backend_message("WRNG", 'viewPerspectiveX', paste("Clonal composition input does not exists at:",clonesIn,". Run clonal decomposition algorithm first.") )
    Sys.sleep(10)
    q()
  }

  p<-.jnew(paste("core",whichP,sep="."),.jnew("java.io.File", clonesIn),"CN_Estimate") 
	backend_message("INFO", 'viewPerspectiveX', p )
  
  ##################
  ####Save to DB####
  if(!is.null(xy)){
    p$setCoordinates(as.double(xy[1]),as.double(xy[2]))
  }
  #
  .jcall(p, returnSig ="V", method = "save2DBX", .jlong(transactionId))
	# backend_message("INFO", 'save2DBX', unused )
  # if(whichP==tP$name()){
  #   for(sp in p$getChildrensSizes()){ ##Save subclone profiles
  #     ##@TODO: save as sparse matrix to DB
  #     p_<-.jnew("core.TranscriptomePerspective",.jnew("java.io.File", gsub("sps",paste(round(sp,NUMRES),"sps",sep="."),clonesIn) ),paste("Clone",sp,sep="_"))
  #     .jcall(p_,returnSig ="V",method = "save2DBX")
  #     ##@TODO: complain if somewthing goes wrong/is incompletely saved! <-- catch exception thrown by java
  #   }
  # }
  # if(whichP==gP$name()){
  #   for(sp in p$getChildrensSizes()){ ##Save subclone profiles
  #     p_<-.jnew("core.GenomePerspective",.jnew("java.io.File", gsub("sps",paste(round(sp,NUMRES),"sps",sep="."),clonesIn) ),paste("SP",sp,sep="_"))
  #     .jcall(p_,returnSig ="V",method = "save2DBX")
  #   }
  # }
  #
  # return(unused)
  if(whichP==mP$name()){
    for(sp in p$getChildrensSizes()){ ##Save subclone profiles
      p_<-.jnew("core.MorphologyPerspective",.jnew("java.io.File", gsub("sps",paste(round(sp,NUMRES),"sps",sep="."),clonesIn) ),paste("SP",sp,sep="_"))
      .jcall(p_,returnSig ="V",method = "save2DBX", .jlong(transactionId))
      # .jcall(p, returnSig ="V", method = "save2DBX", transactionId)
    }
  }
  #display(sampleName,whichP)
}


parse4cloneid_save<-function(f_, xx, OUTDIR, howManyCells=NULL){
  FAKESPSIZE=0.99
  if(endsWith(fileparts(f_)$name,"_bl")){
    xy=c(0,0)
  }else if(endsWith(fileparts(f_)$name,"_tl")){
    xy=c(0,1)
  }else if(endsWith(fileparts(f_)$name,"_br")){
    xy=c(1,0)
  }else if(endsWith(fileparts(f_)$name,"_tr")){
    xy=c(1,1)
  }
  csv=read.csv(f_,sep="\t")
  ##Save only a subset of cells
  if(!is.null(howManyCells)){
    whichCells=sample(1:nrow(csv), min(howManyCells, nrow(csv)) )
    csv=csv[whichCells,]
  }
  ii=sapply(colnames(csv), function(x) is.numeric(csv[,x]))
  csv=csv[,ii]
  csv=as.data.frame(t(csv))
  colnames(csv)=paste0("SP_",1/ncol(csv),"_cellpose",1:ncol(csv))
  ## xx.csv --> average morphology across all cells
  csv_=apply(csv,1,median,simplify = T)
  csv_=as.data.frame(csv_)
  csv_=cbind(rownames(csv_),csv_,csv_)
  colnames(csv_)=c("LOCUS",paste0("SP1_",FAKESPSIZE),"CN_Estimate")
  unused<-write.table(csv_, paste0(OUTDIR,filesep,xx,".sps.csv"),row.names = F,sep="\t",quote = F)
  ## xx.1.0.sps.csv
  csv=cbind(rownames(csv),csv)
  colnames(csv)[1]="LOCUS"
  unused<-write.table(csv, paste0(OUTDIR,filesep,xx,".",FAKESPSIZE,".sps.csv"),row.names = F,sep="\t",quote = F)
  ## xx.spstats
  stats=as.matrix(FAKESPSIZE)
  colnames(stats)="Mean Weighted"
  unused<-write.table(stats, paste0(OUTDIR,filesep,xx,".spstats"),row.names = F,sep="\t",quote = F)
  ## Save to DB
  unused<-viewPerspectiveX(spstatsFile=paste0(OUTDIR_,filesep,xx,".spstats"),"MorphologyPerspective",suffix = ".sps.csv", xy=xy)
}





# dir.create(OUTDIR)

## Run to upload all cell line morphology data to DB
#lineageCLs <-c("NUGC-4_A4_seed","NCI-N87_A59_seed","HGC-27_A22_seed","KATOIII_A6_seed","SNU-668_A9_seed","MKN-45_A4_seed","SNU-638_A4_seed","SNU-601_A4_seed");
# lineageCLs <-c("SNU-668_A9_seed");
# lineageCLs <-c("HGC-27_A1_seedTP48");

# id = "SNU-668_A9_seed"

if (TRUE){

	CURRENT_DIR=getwd()
	backend_message("INFO", 'CURRENT_DIR', CURRENT_DIR)
	setwd(DETECTIONRESULTS_OUTDIR)
	OUTDIR=MORPHOLOGYPERSPECTIVE_OUTDIR

lineageCLs <-c(id);
backend_message("INFO", 'id', id)
backend_message("INFO", 'lineageCLs', lineageCLs)
for(cl in lineageCLs){
  backend_message("INFO", 'cl', cl )
  out=cloneid::findAllDescendandsOf(ids=cl, recursive = F)
  out=out[!is.na(out$date),]
  out=out[order(as.Date(out$date)),]
  f=sapply(out$id, function(xx) list.files(pattern = paste0(xx,"_")), simplify = F)
  f=sapply(f, function(x) c(grep("bl.csv",x,value=T)));
  backend_message("INFO", 'f', f )
  for(xx in names(f)){
    backend_message("INFO", 'OUTDIR_', c(OUTDIR,filesep,xx)) 
  	createDirIfnotExists('OUTDIR_',	c(OUTDIR,filesep,xx))
    unused<-sapply(f[[xx]], function(f_) parse4cloneid_save(f_, xx, OUTDIR_))
    backend_message("INFO", 'unused', unused) 
  }
}

## Test: view uploaded data
# library(cloneid)
# lineageCLs <-c("NUGC-4_A4_seed","NCI-N87_A59_seed","HGC-27_A22_seed","KATOIII_A6_seed","SNU-668_A9_seed","MKN-45_A4_seed","SNU-638_A4_seed","SNU-601_A4_seed");
# cl = lineageCLs[5]
# out=cloneid::findAllDescendandsOf(ids=cl, recursive = F)
# ii=5
if(1==0){
  library(cloneid)
  lineageCLs <-c(id);
  cl = lineageCLs[1]
  out=cloneid::findAllDescendandsOf(ids=cl, recursive = F)
  backend_message("INFO", 'out', out )
  ii=1
  sps=cloneid::getSubclones(cloneID_or_sampleName = out$id[ii],whichP = "MorphologyPerspective")
  backend_message("INFO", 'view uploaded data', sps )
  sps=cloneid::extractID(names(sps))
  backend_message("INFO", 'view uploaded data', sps )
  p=sapply(sps, function(x) getSubProfiles(cloneID_or_sampleName = as.numeric(x), whichP = "MorphologyPerspective"), simplify = F)
  backend_message("INFO", 'view uploaded data', p )
}


setwd(CURRENT_DIR)


	
}


















# Sys.sleep(10)




# # Launch Seed or Harvest 
# if(event == "seeding"){
#   r <- seed(id, from, cellCount, flask, format(as.POSIXlt(Sys.time()),'%Y-%m-%d %H:%M:%S'), media); 
# } else if(event == "harvest"){
#   r <- harvest(id, from, cellCount, format(as.POSIXlt(Sys.time()),'%Y-%m-%d %H:%M:%S')); 
# }


backend_message("JSON", "finalresult", jsonlite::toJSON(finalresult));

finalresultspath = paste0(RESULTS_DIR,"finalresults.csv")
backend_message("RSLT", "finalresults.csv", finalresultspath);
write.csv(finalresult, finalresultspath, row.names=T)

backend_message("DONE", "done", 'end');
# Sys.sleep(5)
# q()

# AVAIL TESTING
# export IVUTEST_CHECKRESULT=TRUE
# export IVUTEST_HANDLEINPUT=TRUE
# export IVUTEST_FORCESETENV=TRUE
# export IVUTEST_USEFAKEARGS=TRUE
# export IVUTEST_NOTIFYTYPES=TRUE






