\name{addSampleSources}
\alias{addSampleSources}
\title{New database entry: cell line or patient identifier.}
\description{Database insert function for table CellLinesAndPatients.}
\usage{addSampleSources(src, doublingTime_hours = NA, type = "patient", from = "MoffittCancerCenter") }
\arguments{
  \item{src}{
     Character vector holding cell lines' or patients' names.
  }
  \item{doublingTime_hours}{
     The doubling time of the cellLine.
  }
  \item{type}{
     Whether these are patients or cell lines.
  }
  \item{from}{
     Origin of cell line or patient samples.
  }
}



