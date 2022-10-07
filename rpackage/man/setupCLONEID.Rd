\name{setupCLONEID}
\alias{setupCLONEID}

\title{
Edit CloneID Configuration Yaml
}
\description{
Function to take user input to set CloneID's MySQL connection: host, port, user, password, database and schema build script location
}
\usage{
setupCLONEID(host = 'localhost', port = '3306', user = NA, password = NA, database="CLONEID", schemaScript = "CLONEID_schema.sql")
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{host}{
string MySQL host domain url
}
  \item{port}{
string MySQL port number, default: 3306
}
  \item{user}{
string MySQL user to connect with
}
  \item{password}{
string MySQL user password, this is used by other CloneID functions to read/write to the MySQL database
}
  \item{database}{
string MySQL database name, default: CLONEID
}
  \item{schemaScript}{
string path to SQL script to build the CLONEID database
}
}
\examples{

# To see current yaml configuration values:
setupCLONEID()

# To set all values:
setupCLONEID('localhost', '3306', 'user1', 'password1', 'CLONEID', 'CLONEID_schema.sql')

# To set select values:
setupCLONEID(host='localhost')

setupCLONEID(port='3306', user='user1')

}
