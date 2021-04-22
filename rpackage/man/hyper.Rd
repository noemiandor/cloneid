\name{hyper}
\alias{hyper}
\title{Subpopulation relatedness assessment}
\description{Calculates probability that two clones are related, modelling overlapping mutations as hypergeometric distribution.}
\usage{hyper(p,r=NULL)}
\arguments{
  \item{p}{
     A numeric vector or matrix holding the mutation profile of one or multiple clones (0 denotes absence; values >0 denote presence).
  }
  \item{r}{
     The mutation profile of the other clone. Can be NULL if p is a matrix.
  }
}
\details{
Let \eqn{SP_P} be a clone within one perspective and \eqn{SP_R} , a clone within another perspective of the same tumor (perspectives may be of same type).  Further, let \eqn{M_P}, \eqn{M_R} be the set of SNVs assigned to \eqn{SP_P} and \eqn{SP_R}, while \eqn{M_{PR}} is the set of overlapping SNVs between \eqn{SP_P} and \eqn{SP_R}. 
We calculate how likely is it to observe at least |  \eqn{M_{PR}} | common SNVs between \eqn{SP_P} and \eqn{SP_R} just by chance, by calculating:
\bold{a})	how likely it is to observe at least |  \eqn{M_{PR}} | common SNVs in  \eqn{SP_P}
\bold{b})	how likely it is to observe at least |  \eqn{M_{PR}} | common SNVs in  \eqn{SP_R}
Both probabilities are modeled as Hypergeometric distributions: For (\bold{b}), we draw x \eqn{\in} \eqn{M_R} and each time x  \eqn{\in} MP we count the draw as success.  Conversely, if x \eqn{\notin} \eqn{M_P}, the draw is considered a failure. For (\bold{a}) we proceed in the same way, but reverse the role of \eqn{SP_R} with that of \eqn{SP_P}. The likelihood that  \eqn{SP_P} is related to \eqn{SP_R} is calculated as the minimum among the two probabilities (\bold{a,b}).

}
\value{Probability that \eqn{SP_P} is related to \eqn{SP_R}.}

\author{Noemi Andor}

\examples{
  
}




