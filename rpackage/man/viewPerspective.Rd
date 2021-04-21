\name{viewPerspective}
\alias{viewPerspective}
\title{Biosample's subclonal composition inference}
\description{Reads the subclonal composition of a biosample and adds it to the SQL table `Perspective`.}
\usage{viewPerspective(spstatsFile, whichP, tissue = NULL, suffix = ".sps.cbs", xy = NULL)}
\arguments{
  \item{spstatsFile}{
     The path towards .spstats file: data.frame with each row denoting a subpopulation and columns denoting their IDs and cellular fractions. \cr \cr    
     The the file must be named according to the sample of origin of the profiled cells. \cr \cr
     The file must be in a directory containing the output of a clonal decomposition algorithm. See \code{\link{CloneProfiles}} for format requirements of output files.
  }
  \item{whichP}{
     What this assay provides: GenomePerspective or TranscriptomePerspective.
  }
  \item{tissue}{
     The tissue type of the specimen.
  }
  \item{suffix}{
     The suffix of the file within the output directory, containing the desired perspective.
  }
  \item{xy}{
     Two-dimensional vector containing the geographic location of the specimen.
  }
 
}
\details{
	Profiles of the subpopulations listed in the .spstats file will be added to the SQL table `Perspective`.
}

\author{Noemi Andor}






