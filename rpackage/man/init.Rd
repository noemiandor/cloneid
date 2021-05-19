\name{init}
\alias{init}
\title{New database entry: The first harvest associated with a cell line.}
\description{Database insert function for table Passaging.}
\usage{init(id, cellLine, cellCount, tx = Sys.time(), media=NULL, flask=NULL) }
\arguments{
  \item{id}{
     The prefix of the file holding brightfield image(s) associated with this harvest event. This will be used as key in the Passaging table.
  }
  \item{cellLine}{
     The cellLine from which these cells were harvested.
  }
  \item{cellCount}{
     Technician's best guess on how many cells are in the flask at the time of harvest. This is only for comparison with cell count inferred from segmentation algorithm and will not be saved to the database.
  }
  \item{flask}{
     The ID of the flask type from which the cells were harvested. If this is NULL, images will be ignored.
  }
  \item{tx}{
     Timestamp at which the harvest was performed. Defaults to current system time.
  }
  \item{media}{
     ID of the media used to grow these cells (key in SQL table `Media`).
  }
}



