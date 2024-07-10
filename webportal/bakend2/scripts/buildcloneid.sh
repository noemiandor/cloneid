#!/bin/bash

cd /home/rstudio/cloneid || exit 1
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ulimit -c unlimited
R CMD javareconf
rm build/libs/cloneid.jar 

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/; ulimit -c unlimited; ./gradlew --no-build-cache && echo GRADLE1 BUILD SUCCESSFUL
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/; ulimit -c unlimited; ./gradlew clean            && echo GRADLE2 CLEAN SUCCESSFUL

while [ ! -f build/libs/cloneid.jar ]; do

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/; ulimit -c unlimited; ./gradlew uberJar          && echo GRADLE3 BUILD SUCCESSFUL

done

cp build/libs/cloneid.jar rpackage/inst/java/cloneid.jar && echo JAR COPY SUCCESSFUL
R CMD build rpackage && echo RBUILD SUCCESSFUL
R CMD INSTALL cloneid_1.2.1.tar.gz && echo RINSTALL SUCCESSFUL
