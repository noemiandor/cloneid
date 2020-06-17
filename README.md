# CloneID

### Contents 

1. [Requirements](#requirements)
1. [Clone GIT Repository](#clone-git-repository)
1. [Linux and OSX Setup](#linux-and-osx-setup)
1. [Set Java Version for R](#set-java-version-for-r)
1. [Build R Package](#build-r-package)
1. [Windows Setup](#windows-setup)
1. [Running the Package in R](#running-the-package-in-r)
1. [MySQL Database Setup](#mysql-database-setup)
1. [Build CloneID Jar](#build-cloneid-jar)
1. [Troubleshooting](#troubleshooting)

### Requirements 
CLONEID requires the followwing software and versions. 
1. [Java](https://www.java.com/) version 8, 9, 10, 11, 12, or 13 
1. [MySQL Server version 8](https://dev.mysql.com/downloads/mysql/8.0.html#macosx-dmg)
1. [XQuartz](https://www.xquartz.org/) (may be needed. OSX only)
1. [R version 3.6+](https://www.r-project.org/). Additionally, make sure that the following R packages are installed.

#### R Packages
1. rJava 
1. qualV 
1. RColorBrewer
1. gtools
1. gplots
1. ape 
1. gdata
1. RMySQL
1. flexclust 
1. Matrix 
1. liayson
1. expands
1. matlab
1. yaml 
1. biomaRt (from [Bioconductor](https://bioconductor.org/packages/release/bioc/html/biomaRt.html))

In an **R terminal** run the following commands:
```r 
# R v3.6
> if (!requireNamespace("BiocManager", quietly = TRUE)) { install.packages("BiocManager") }
> BiocManager::install("biomaRt")
> install.packages(c('rJava', 'qualV', 'RColorBrewer', 'gtools', 'gplots', 'ape', 'gdata', 'RMySQL', 'flexclust', 'Matrix', 'liayson', 'expands', 'matlab', 'yaml'))
```
## Linux and OSX Setup

### Set Java variables for R 

- In a shell prompt (or command line or terminal), run this command:
```sh 
$ R CMD javareconf
```
- Example output

```text
Java interpreter : /usr/bin/java
Java version     : 1.8.0_25
Java home path   : /Library/Java/JavaVirtualMachines/jdk1.8.0_25.jdk/Contents/Home/jre
Java compiler    : /usr/bin/javac
Java headers gen.: /usr/bin/javah
Java archive tool: /usr/bin/jar

trying to compile and link a JNI program 
detected JNI cpp flags    : -I$(JAVA_HOME)/../include -I$(JAVA_HOME)/../include/darwin
detected JNI linker flags : -L$(JAVA_HOME)/lib/server -ljvm
clang -I"/Library/Frameworks/R.framework/Resources/include" -DNDEBUG -I/Library/Java/JavaVirtualMachines/jdk1.8.0_25.jdk/Contents/Home/jre/../include -I/Library/Java/JavaVirtualMachines/jdk1.8.0_25.jdk/Contents/Home/jre/../include/darwin  -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -I/usr/local/include  -fPIC  -Wall -g -O2  -c conftest.c -o conftest.o
clang -dynamiclib -Wl,-headerpad_max_install_names -undefined dynamic_lookup -single_module -multiply_defined suppress -L/Library/Frameworks/R.framework/Resources/lib -L/usr/local/lib -o conftest.so conftest.o -L/Library/Java/JavaVirtualMachines/jdk1.8.0_25.jdk/Contents/Home/jre/lib/server -ljvm -F/Library/Frameworks/R.framework/.. -framework R -Wl,-framework -Wl,CoreFoundation

JAVA_HOME        : /Library/Java/JavaVirtualMachines/jdk1.8.0_25.jdk/Contents/Home/jre
Java library path: $(JAVA_HOME)/lib/server
JNI cpp flags    : -I$(JAVA_HOME)/../include -I$(JAVA_HOME)/../include/darwin
JNI linker flags : -L$(JAVA_HOME)/lib/server -ljvm
Updating Java configuration in /Library/Frameworks/R.framework/Resources
Done.

```

### Clone GIT Repository

- In a shell prompt (or command line or terminal) change the current working directory to the location where you want the cloned directory to be made. Then, run this command:
```sh 
$ git clone https://github.com/noemiandor/cloneid.git
```
- Your local CLONEID repo will be created.
```text
Cloning into 'cloneid'...
remote: Enumerating objects: 9, done.
remote: Counting objects: 100% (9/9), done.
remote: Compressing objects: 100% (7/7), done.
remote: Total 208 (delta 4), reused 7 (delta 2), pack-reused 199
Receiving objects: 100% (208/208), 9.85 MiB | 12.72 MiB/s, done.
Resolving deltas: 100% (65/65), done.
```

### Build R Package

- In the repository's root directory use the following command:
```sh 
$ R CMD build rpackage
```

#### Install R Package Method 1

- In a shell prompt run this command after [building the R Package](#build-r-package): 
```sh 
$ R CMD INSTALL cloneid_1.1.0.tar.gz
```

#### Install R package Method 2

- In an R terminal:
```r 
> install.packages('rpackage', repos=NULL, type='source')
```  

## Windows Setup  

### Install Java for Windows  

1. Install newest version of Java (Java 14 at time of this writing)

### Clone GIT Repository  

- [Reference above](#clone-git-repository)

### Build R Package 

- Add R to PATH, this is not automatically down on Windows R installations
- Install RTools for Windows [download page](https://cran.r-project.org/bin/windows/Rtools/)
- Continue here: [Reference above](#build-r-package)

#### Install R Package Method 1  

- [Reference above](#install-r-package-method-1)

#### Install R Package Method 2  

- [Reference above](#install-r-package-method-2)


## Running the package in R 

- To test the installation, in an R terminal run this command:
```r 
> library(cloneid)
> editCloneidConfig()
```

- Output: 

```text 
$mysqlConnection
$mysqlConnection$host
[1] "localhost"

$mysqlConnection$port
[1] 3306

$mysqlConnection$user
NULL

$mysqlConnection$password
NULL

$mysqlConnection$database
[1] "CLONEID"

$mysqlConnection$schemaScript
[1] "CLONEID_schema.sql"
```

## MySQL Database Setup

- Run this command, in an R terminal, to see the current yaml configuration settings for the CloneID Schema:
```r 
> editCloneidConfig()
```

- Run this command, in an R temrinal, to edit the yaml configuration file for the CloneID Schema:
	- Do not include fields you do not want to update
	- The **schemaScript** argument will first look in the **cloneid R package library** directory first and in this case only the file name is needed.  
		- /path/to/&lt;cloneid R library>/sql
	- If another script is used outside of the cloneid R package library directory then the absolute path to that script my be provided
	
```r 
> library(cloneid)
> editCloneidConfig(host='localhost', port='3306', user='USER', password='PASSWORD', database='CLONEID', schemaScript='CLONEID_schema.sql')
``` 

- Run this command, in an R terminal, to create the MySQL CloneID Schema:
```r 
> createCloneidSchema()
```
```text 
# Example output
** CLONEID Schema created successfully ** 
```

## Build CloneID JAR

- The git repository comes with the executable jar.  If you would like to rebuild it use this command in the repository's root directory:
```sh 
$ ./gradlew uberJar
```

- The jar will be placed in:
```text 
build/libs/cloneid.jar
```
- If you make changes to the jar you will need to add it to the R package and then rebuild the package and reinstall it into R 
- The rebuilt jar should be placed here:

```text 
rpackage/inst/java/
```

## Troubleshooting 

#### OSX

- When installing the rJava package in R, it is possible you will encounter errors.  They are often fixed by installing:
	- Xcode (found in the AppStore)
	- Command Line Tools for [Xcode](http://osxdaily.com/2014/02/12/install-command-line-tools-mac-os-x/) 
	```sh 
	$ xcode-select --install
	```
	- **After installation do not forget to run javareconf again**:
	```sh 
	$ R CMD javareconf
	```

#### Windows

- When installing rJava on Windows, if you receive any errors from rJava when importing it in R that look like the message below, you may need to make sure a 32-bit **and** 64-bit version of Java are installed.  This seems to only be the case with older Java versions (i.e. Java 8).  Newer versions of Java only require the 64-bit version:
```text 
Error : .onLoad failed in loadNamespace() for 'rJava', details:   call: inDL(x, as.logical(local), as.logical(now), ...)   
error: unable to load shared object 'C:/Users/USER/Documents/R/win-library/VERSION/rJava/libs/x64/rJava.dll':   
LoadLibrary failure:  The specified module could not be found.  
Error: package or namespace load failed for ‘rJava’
```
