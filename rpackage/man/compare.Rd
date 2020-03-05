\name{compare}
\alias{compare}
\title{Comparing clone perspectives}
\description{Compares two clones with respect to user-specified perspectives.}
\usage{compare(cloneID1,cloneID2,perspective1="GenomePerspective",perspective2="GenomePerspective", col=NULL, plotType = "scatter")}
\arguments{
  \item{cloneID1}{
     The ID of the first clone (integer).
  }
  \item{cloneID2}{
     The ID of the second clone (integer).
  }
  \item{perspective1}{
     The perspective on the first clone: GenomePerspective or TranscriptomePerspective.
  }
  \item{perspective2}{
     The perspective on the second clone: GenomePerspective or TranscriptomePerspective.
  }
  \item{col}{
     The colors according to which to code clones.
  }
  \item{plotType}{
     Whether to make a scatter plot (plotType = "scatter") or heatmap (plotType = "heatmap").
  }
 
}
\details{
}

\author{Noemi Andor}

\examples{
    #par(mfrow=c(3,1))
    #display(cloneID_or_sampleName = "KATOIII",whichP = "GenomePerspective", colorBy = NULL, deep = F, save = F)
    #display(cloneID_or_sampleName = "KATOIII",whichP = "TranscriptomePerspective", colorBy = NULL, deep = F, save = F)
    #compare(4,1,perspective1 = "GenomePerspective",perspective2 = "TranscriptomePerspective", col = NULL, plotType = "scatter")
}




