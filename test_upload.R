## Record "genotypic" information into CLONEID
options(java.parameters = "-Xmx7g")
setwd("~/Repositories/cloneid/")
PREFIX="TEST3_"
## Note: this includes cell morphology info. Referring to a morphology feature as “genotype” is technically not correct. We will need to come up with a better name
library(cloneid)
library(liayson)
library(matlab)
data(CloneProfiles)

# Initialize log file
log_file <- "~/Downloads/process_time_log.txt"
cat("Processing Time Log\n", file = log_file, append = FALSE) # Create or overwrite the log file

start_time <- Sys.time()

for(p in names(CloneProfiles)){
  dataset_start_time <- Sys.time()
  print(paste("Number of cells in",p,"dataset:",sum(sapply(CloneProfiles[[p]],ncol))))
  OUT=paste0("~/Downloads/testViewPerspective",filesep,p)
  dir.create(OUT,recursive = T)
  for(name in names(CloneProfiles[[p]])){
    tab=CloneProfiles[[p]][[name]]
    ii=grep("Clone_",colnames(tab))
    ii=union(ii, grep("SP_",colnames(tab)) )
    if(length(ii)>0){
      tab[,ii] = apply(tab[,ii], 2, function(x) sample(x, length(x)))
    }
    write.table(tab,file=paste0(OUT,filesep, PREFIX,name),sep="\t",quote=F,row.names = F)
  }
  name=paste0(PREFIX,grep("spstats",names(CloneProfiles[[p]]),value=T))
  suffix=paste0(PREFIX,grep("spstats",names(CloneProfiles[[p]]),invert = T, value=T)[1])
  suffix=gsub(fileparts(name)$name,"",suffix)
  viewPerspective(spstatsFile =paste0(OUT,filesep,name), whichP = p,suffix = suffix)

  dataset_end_time <- Sys.time()
  # Log the time taken for the entire dataset processing
  cat(sprintf("Dataset: %s - Time taken: %.2f minutes\n", p, as.numeric(difftime(dataset_end_time, dataset_start_time, units = "mins"))), file = log_file, append = TRUE)
}

end_time <- Sys.time()
total_time <- as.numeric(difftime(end_time, start_time, units = "mins"))
cat(sprintf("Total Processing Time: %.2f minutes\n", total_time), file = log_file, append = TRUE)
