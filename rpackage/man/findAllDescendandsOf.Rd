\name{findAllDescendandsOf}
\alias{findAllDescendandsOf}
\title{Search database for all descendants of a lineage}
\description{Database search function for table Passaging.}
\usage{findAllDescendandsOf(ids, mydb = NULL, recursive=T)}
\arguments{
  \item{ids}{
     Character vector with each entry holding an ID of a lineage (i.e. a key in the Passaging table).
  }
  \item{mydb}{
     Object used to communicate with the database engine. If set to NULL, a new object is created.
  }
  \item{recursive}{
     Whether to return the immediate descendants of the IDs or all progeny.
  }
}
\details{
	For each input ID, returns all lineages from the Passaging table that can be traced back to this ID.
}

\author{Noemi Andor}

