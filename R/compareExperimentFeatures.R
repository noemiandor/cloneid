compareExperimentFeatures <- function(ids1, ids2){
  stmt=paste0("select * from Passaging where id in (\'",paste(c(ids1, ids2), collapse = "\',\'"),"\')");
  
  mydb = dbConnect(MySQL(), user = Sys.info()["user"], password = "lalalala", 
                   dbname = "CLONEID", host = "cloneredesign.cswgogbb5ufg.us-east-1.rds.amazonaws.com")
  
  rs = dbSendQuery(mydb, stmt)
  o = fetch(rs, n = -1)
  rownames(o)= o$id

  o$date=as.Date(o$date)
  o$deltaPassage <- o$timeToGrow <- o$ratioCells <- NA
  for(i in rownames(o)[!is.na(o$passaged_from_id1)]){
    j=which(o$id==o[i,"passaged_from_id1"])
    if(o[i,"event"]=="harvest" & o[j,"event"]=="seeding"){
      o[i,"timeToGrow"] = o[i,"date"] - o[j,"date"]
      o[i,"ratioCells"] = o[i,"cellCount"] /o[j,"cellCount"]
    }
    o[i,"deltaPassage"] = o[i,"passage"] - o[j,"passage"]
  }
  o$growthRate=o$ratioCells/o$timeToGrow
  o$confluence=o$cellCount/max(o$cellCount, na.rm = T)
  
  ##Make boxplots
  o$replicate = 1;
  o$replicate[o$id %in% ids2] = 2
  o$replicate = as.factor(o$replicate)
  
  
  cpc = reshape::melt((o),id.vars="replicate", measure.vars=c("growthRate","deltaPassage", "confluence")); 
  
  e <- ggplot(cpc, aes(x = variable, y = value))
  e + geom_boxplot(aes(fill = replicate),position = position_dodge(0.9)   ) + theme(
    axis.text.x = element_text( size=14, face="bold"),
    legend.title = element_text( size=14, face="bold"),
    axis.title.x = element_text(color="white"),
    axis.title.y = element_text(color="white")
  ) + ylim(0,2.5)
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
}