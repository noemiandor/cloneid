getSubProfiles <- function (cloneID_or_sampleName, whichP = "TranscriptomePerspective", includeRoot = FALSE) {
  persp = J("core.utils.Perspectives")$valueOf(whichP)
  whichP_=gsub("Morphology","", gsub("Exome","",gsub("Genome","",gsub("Transcriptome","",whichP))))  

  cloneID = cloneID_or_sampleName;
  if (class(cloneID_or_sampleName) == "character") {
    cloneID = getRootID(cloneID_or_sampleName, whichP)
  }
  
  p <- .jcall("cloneid.Manager", returnSig = "Ljava/util/Map;", method = "profiles", as.integer(cloneID), persp, as.logical(includeRoot))
  dat = .javamap2Rmatrix(p);
  
  return(dat)
}

