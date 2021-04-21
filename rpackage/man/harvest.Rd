\name{harvest}
\alias{harvest}
\title{New database entry: at any time before harvesting cells from a flask.}
\description{Database update function for table Passaging.}
\usage{harvest(id, from, cellCount, tx = Sys.time(), media=NULL)}
\arguments{
  \item{id}{
     The prefix of the file holding brightfield image(s) associated with this harvest event. This will be used as key in the Passaging table.
  }
  \item{from}{
     The ID of the seeding event from which these cells were harvested.
  }
  \item{cellCount}{
     Technician's best guess on how many cells are in the flask at the time of harvest. This is only for comparison with cell count inferred from segmentation algorithm and will not be saved to the database.
  }
  \item{tx}{
     Timestamp at which the harvest was performed. Defaults to current system time.
  }
  \item{media}{
     ID of the media used to grow these cells (key in SQL table `Media`).
  }
}
\details{
	CLONEID's lineage tracing module streamlines routine monitoring of three aspects of in-vitro experiments: (i) the pedigree of all cell lineages grown in a lab; (ii) the exact media composition in which the cells grow and (iii) how often cells divide. Automatic recording of this information in the SQL table passaging requires technicians to adopt two new habits: (1) taking brightfield images of live cells both, immediately after seeding and any number of times before harvest. (2) Passing the images to CLONEID's \textit{seed} and \textit{harvest} functions respectively. This function facilitates the latter.
}

\author{Noemi Andor}







