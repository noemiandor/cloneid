getAlias<-function (cloneID, whichP = "TranscriptomePerspective") {
  return(getAttribute(cloneID, whichP, attr="alias"))
}
