getState<-function (cloneID,whichP = "TranscriptomePerspective") {
  return(getAttribute(cloneID, whichP, attr="state"))
}
