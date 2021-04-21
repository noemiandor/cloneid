viewAllExperiments <- function(cellLine, n_time=2){
  stmt=paste0("select * from Passaging where cellLine=\'",cellLine,"\' and comment is null or (comment not like '%C%' and comment not like '%B%')");
  
  mydb = .connect2DB()
  
  rs = dbSendQuery(mydb, stmt)
  o = fetch(rs, n = -1)
  o[,"date"] = as.Date(o[,"date"])
  rownames(o)=o$id
  ##@TODO: remove -- for demo pursposes only:
  ii = grep("A2",rownames(o), value=T)
  o[ii,"date"] = o[ii,"date"] + 14
  o=o[!rownames(o) %in% c("SNU-16","24"),]
  ##
  o = o[sort(as.character(o[,"date"]), index.return=T)$ix,];
  o = o[round(0.2*nrow(o)):nrow(o),] ##Don't start @ day one <-- @TODO -- start from begining and zoom instead
  o$day = as.numeric(o[,"date"]-o[1,"date"])
  
  plot(c(o$day[1]-1,max(o$day)+1),c(0,0.25), col="white", xlab="day", ylab="",bty='l', axes = FALSE, ann = FALSE)
  axis(1, at = seq(o$day[1],max(o$day)+1, b=5)); mtext("day", side=1, line = 2)
  cols = cols = gg_color_hue(n_time)
  ###################################################
  ###within a day -- assume no more than 1 depth! ##
  o$x <- o$y <- NA; ## add x & y coord in plot
  o$timeCluster = kmeans(o$day,n_time)$cluster
  for(x in unique(o$timeCluster)){
    o$y[o$timeCluster==x]=(c(sum(o$timeCluster==x, na.rm=T):0)/10)^3
  }
  for(day in sort(unique(o$day),decreasing = T)){
    o_=o[o$day== day,]
    pfis = unique(o_$passaged_from_id1)
    pfis = pfis[!is.na(pfis)]
    for(pfi in pfis){
      ids = o_$id[which(o_$passaged_from_id1==pfi)]
      ## offset seeding-harvest 0.3 along x-axis;
      ## offset each passaged_from_id apart 0.1 along y-axis:
      o[pfi,"x"]=day - 0.3;  ##@TODO: doesn't work pfi==unique(o_$passaged_from_id1) is true for >10 pfi
      for(id in ids){
        ## offset each id apart 0.01 along y-axis
        o[id,"x"]=day + 0.3
        points(o[id,"x"], o[id,"y"], col="cyan", pch=20); 
        text(o[id,"x"], o[id,"y"], id, cex = 0.65)
      }
      ## Connect for Same day only! :
      ids = ids[o[ids,"day"] == o[pfi,"day"]]; 
      for(id in ids){
        points(o[pfi,"x"], o[pfi,"y"], col="cyan", pch=20)
        text(o[pfi,"x"], o[pfi,"y"], pfi, cex = 0.65)
        # lines(o[c(pfi,id),"x"], o[c(pfi,id),"y"], col=cols[1]); 
        arrows(o[pfi,"x"], o[pfi,"y"], x1 = o[id,"x"], y1 = o[id,"y"], col=cols[o[id,"timeCluster"]])
        text(o[id,"x"], o[id,"y"], id, cex = 0.65)
      }
    }
  }
  
  #################
  ###across days###
  for(pfi in unique(o$passaged_from_id1)){
    ids = o$id[which(o$passaged_from_id1==pfi)]
    ids = ids[o[ids,"day"] != o[pfi,"day"]];
    ids=ids[!is.na(ids)]
    ## ## if id has different date than passaged_from_id1 --> connect using saved xy-coord
    for(id in ids){
      daydiff = o[id,"x"] - o[pfi,"x"]
      col = cols[o[id,"timeCluster"]]
      if(o[id,"timeCluster"]!=o[pfi,"timeCluster"]){
        col="black"
      }
      arrows(o[pfi,"x"], o[pfi,"y"], x1 = o[id,"x"], y1 = o[id,"y"], col=col); #,lty=3
      # lines(o[c(pfi,id),"x"], o[c(pfi,id),"y"], col=cols[min(length(cols),1+daydiff)]); #lty=3
    }
  }
  
  
  dbClearResult(dbListResults(mydb)[[1]])
  dbDisconnect(mydb)
  
}

gg_color_hue <- function(n) {
  hues = seq(15, 375, length = n + 1)
  hcl(h = hues, l = 65, c = 100)[1:n]
}

