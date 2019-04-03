getCloneMembers<-function(sName, type="Dominant", whichP="GenomePerspective"){
  clones=cloneid::getSubclones(sName,whichP)
  dc=clones[which.max(lapply(names(clones), getSPsize))]
  if(type!="Dominant"){
    dc=clones[names(clones)!=names(dc)]
  }
  dcID=unlist(lapply(names(dc), function(x) strsplit(x,"_ID")[[1]][2]))
  members=lapply(dcID, function(x) cloneid::getSubclones(as.integer(x), whichP))
  members=unlist(members)
  return(members)
}