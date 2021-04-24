\name{getSubclones}
\alias{getSubclones}
\title{Retrieving subclones}
\description{Given the name of a biosample or the ID of a clone, the method retrieves all its subclones.}
\usage{getSubclones(cloneID_or_sampleName,whichP="GenomePerspective")}
\arguments{
  \item{cloneID_or_sampleName}{
     Clone ID (integer) or biosample name (character).
  }
  \item{whichP}{
     What to vizualize: GenomePerspective (default), TranscriptomePerspective or Identity.
  }
 
}
\details{
}
\value{A map of each clone to its unique ID.
}

