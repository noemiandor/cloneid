\name{viewPerspective}
\alias{viewPerspective}
\title{Biosample's subclonal composition inference}
\description{Calculates user-specified perspective of the subclonal composition of a biosample and saves it to the database.}
\usage{viewPerspective(pathToSample, whichP, tissue = NULL, expandsD ="expands", liaysonD = "liayson", suffix = ".sps.cbs", xy = NULL)}
\arguments{
  \item{pathToSample}{
     The path towards the perspective to be viewed (character). If no such path is found, cloneID will call the corresponding algorithm to create it.
  }
  \item{whichP}{
     What to calculate: GenomePerspective or TranscriptomePerspective.
  }
  \item{tissue}{
     The tissue type of the specimen.
  }
  \item{expandsD}{
     The output directory for the GenomePerspective.
  }
  \item{liaysonD}{
     The output directory for the TranscriptomePerspective.
  }
  \item{suffix}{
     The suffix of the file within the output directory, containing the desired perspective.
  }
  \item{xy}{
     Two-dimensional vector containing the geographic location of the specimen.
  }
 
}
\details{
}

\author{Noemi Andor}





