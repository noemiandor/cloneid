\name{parseLOCUS}
\alias{parseLOCUS}
\title{Parsing locus string to numeric}
\description{Transforms locus string "chr:start-end" to three corresponding numeric values.}
\usage{parseLOCUS(loci)}
\arguments{
  \item{loci}{
     Vector of strings holding genomic coordinates.
  }
}
\value{Numeric matrix with columns "chr", "startpos", "endpos".}

\author{Noemi Andor}

