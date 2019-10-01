getRootID<-function(sampleName, whichP){

  yml = read_yaml(paste0(system.file(package='cloneid'), '/config/config.yaml'))
  mydb = dbConnect(MySQL(), user=yml$mysqlConnection$user, password=yml$mysqlConnection$password, dbname=yml$mysqlConnection$database,host=yml$mysqlConnection$host, port=as.integer(yml$mysqlConnection$port))
  
  whichP_ = gsub("Exome", "", gsub("Genome", "", gsub("Transcriptome", "", whichP)))
  stmt = paste0("select cloneID from ", whichP_, " where whichPerspective='",
                whichP, "' AND sampleName='", sampleName, "' AND parent IS NULL")
  rs = dbSendQuery(mydb, stmt)
  root = fetch(rs, n = -1)
  return (as.numeric(root$cloneID))
}
