\name{merge}
\alias{merge}
\title{Merging perspectives into clones' identities}
\description{Merges either two different perspectives on the clonal composition of the same specimen OR the same perspective on the clonal composition of two or more different specimens to approximate each clone's identity as the consensus across perspectives/specimens. Resulting consensus profiles are added to the SQL table `Identity`. No new entry is made if no two perspectives agree on the existence of any clone.}
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
  Let \eqn{S_i} be the set of subpopulations detected in sample i and  \eqn{S:= \bigcup S_i} – the set of clones detected across all biopsies of a given patient. Further let  \eqn{L} be the set of all non-private loci, in which an SNV is detected in at least two samples and \eqn{M_x \subset L} the set of loci mutated in \eqn{x \in S_i}.\cr\cr

Next, subpopulations  \eqn{S} are grouped into categories by hierarchical cluster analysis of their SNV profiles  \eqn{M_S}, using a distance metric defined by the hypergeometric probability calculated above (agglomeration method: "single").  Subpopulations from distinct samples, falling within the same category (hypergeometric  \eqn{P \geq t}) are considered different perspectives on the same clone. 

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
  #display(cloneID_or_sampleName = "KATOIII",whichP = "GenomePerspective")display(cloneID_or_sampleName,whichP="GenomePerspective", colorBy = NULL, deep = F, save = F)
  #display(cloneID_or_sampleName,whichP="TranscriptomePerspective", colorBy = NULL, deep = F, save = F)
  #merge(perspectives=c("GenomePerspective", "TranscriptomePerspective"), specimens="KATOIII", simM = "euclidean", t=-Inf)
  ##compare(4,1,perspective1 = "GenomePerspective",perspective2 = "Identity")
}



