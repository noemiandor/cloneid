buildCellPoseEnvironment = function(){
  if('cellpose' %in% reticulate::conda_list()$name){
    confirmError = ""
    while(!confirmError %in% c("yes", "no")){
      confirmError <- readline(prompt="A conda environment named 'cellpose' already exists. Are you sure you want to delete it and install a new one? This is typically only necessary when installing cloneid for the first time. Type 'yes' to continue, 'no' to abort: ")
    }
  }
  if(tolower(confirmError)=="yes"){
    system("conda env remove -n cellpose")
    system(paste0("conda env create --name cellpose --file=",find.package("cloneid"),filesep,"python",filesep,"environment.yml"))
  } 
}
