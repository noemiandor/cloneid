\name{createCloneidSchema}
\alias{createCloneidSchema}

\title{
Create CLONEID Schema in MySQL
}
\description{
Function to create the CLONEID Schema in MySQL defined by the connection configuration yaml set in editCloneidConfig()
}
\usage{
createCloneidSchema(forceCreateSchema = FALSE)
}

\arguments{
    \item{forceCreateSchema}{(boolean) If TRUE the current CLONEID database will be dropped and the schema recreated.  WARNING: This will delete all data in CLONEID}
}

\examples{
# Create the CLONEID MySQL Schema (safe)
createCloneidSchema(forceCreateSchema = FALSE)

# Create the CLONEID MySQL Schema AND drop CLONEID database if exists
createCloneidSchema(forceCreateSchema = TRUE)
}
