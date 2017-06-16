\name{display}
\alias{display}
\title{Visualization of a biosample's/clone's subclonal composition}
\description{Given the name of a biosample or the ID of a clone, the method displays its subclonal composition.}
\usage{display(cloneID_or_sampleName,whichP="GenomePerspective", colorBy = NULL, deep = F, save = F)}
\arguments{
  \item{cloneID_or_sampleName}{
     Clone ID (integer) or biosample name (character).
  }
  \item{whichP}{
     What populations to vizualize: GenomePerspective (default), TranscriptomePerspective or Identity.
  }
  \item{colorBy}{
     What aspect of the populations vizualize: GenomePerspective>XX, TranscriptomePerspective>XX or Identity>XX, where XX is a specific locus within the chosen perspective and is optional. 
  }
  \item{deep}{
     Whether to display the direct subclones or go one level deeper and display the subclones' subclones. 
  } 
  \item{save}{
     Whether to save the plot as .tif file.
  }  
}
\details{
}

\author{Noemi Andor}

\examples{
  
}




