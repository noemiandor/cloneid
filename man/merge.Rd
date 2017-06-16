\name{merge}
\alias{merge}
\title{Merging perspectives into clones' identities}
\description{Merges either 2 different perspectives on the clonal composition of the same specimen OR the same perspective on the clonal composition of 2 or more different specimens to approximate each clone's identity as the consensus across perspectives/specimens.}
\usage{merge(perspectives, specimens, simM = "euclidean", t=-Inf)}
\arguments{
  \item{perspectives}{
     Minimal one and maximal two perspectives on a specimen. Two perspectives are required if only one specimen is provided.
  }
 \item{specimens}{
      The name of the specimen(s). Exactly one specimen is required if more than one perspectives are provided. Two or more specimens are required if only one perspective is provided.
  }
 \item{simM}{
     What similarity measure to use in order to match clonal components across perspectives/specimens. Options are: inverse of euclidean distance (euclidean - default), correlation coefficient (either pearson or spearman), mutation overlap significance as assessed by hypergeometric distribution (hyper).
  }
 \item{t}{
     Minimum similarity threshold below which two subpopulations will no longer be merged.
  }
 
}
\details{
  Propagates through clonal compositions inferred for user-specified perspectives/specimens \eqn{P_1}...\eqn{P_n} and links them. Clone \eqn{SP_a} \eqn{\in} \eqn{P_i} is linked to clone \eqn{SP_b} \eqn{\in} \eqn{P_{i+1}} based on maximizing relatedness across all inter-perspective subpopulation pairs (see \code{\link{spRelatednessP}}). Thereby, the algorithm propagates subpopulation links across regions.
}

\value{List with four fields:
\item{sp2clone}{
       Matrix with rows denoting clones and columns holding the different perspectives on a clone. 
       Entries contain the size of each clone and its ID in the database.
       Last column contains the Identity of each clone calculated across the preceding columns.
}
\item{sp2clone_sim}{
       Matrix with rows denoting clones and columns holding the different perspectives on a clone. 
       Entries contain a measure of how confidently a clone could be assigned to the clone from the preceding column.  
}
\item{consdat}{
       The consensus profile of each clone.
}
\item{usedOrder}{
       The path taken through persepctives to match clones.
}
}


\author{Noemi Andor}

\examples{
  #par(mfrow=c(4,1))
  #display(cloneID_or_sampleName = "KATOIII",whichP = "GenomePerspective")
  #display(cloneID_or_sampleName = "KATOIII",whichP = "TranscriptomePerspective")
  #merge(perspectives=c("GenomePerspective", "TranscriptomePerspective"), specimens="KATOIII")
  ##compare(4,1,perspective1 = "GenomePerspective",perspective2 = "Identity")
}



