\name{feed}
\alias{feed}
\title{{Database update: record feeding.}}
\description{Database update function for table Passaging.}
\usage{ feed(id, tx=Sys.time()) }
\arguments{
  \item{id}{
     The ID of the seeding event of the cells that are being fed. This will be used to search the Passaging table.
  }
  \item{tx}{
     Timestamp at which the seeding was performed. Defaults to current system time.
  }
}
\details{
	Entry associated with the seeding ID will be updated with a timestamp indicating a feeding.
}

\author{Noemi Andor}







