\name{getSubProfiles}
\alias{getSubProfiles}
\title{Retrieving subclone profiles}
\description{Given the name of a biosample or the ID of a clone, the method retrieve the profiles of all its subclones.}
\usage{getSubProfiles(cloneID_or_sampleName,whichP="TranscriptomePerspective", includeRoot = FALSE)}
\arguments{
  \item{cloneID_or_sampleName}{
     Clone ID (integer) or biosample name (character).
  }
  \item{whichP}{
     What to vizualize: GenomePerspective (default), TranscriptomePerspective or Identity.
  }
  \item{includeRoot}{
     Whether or not to include the parent clone's profile into the output.
  }
 
}
\details{
}
\value{A matrix with rows corresponding to features and columns corresponding to subclones.
}

\

\examples{
  pm=getSubProfiles(cloneID_or_sampleName = "LGG2T1",whichP = "GenomePerspective", includeRoot = FALSE)
}




