JAVA_SRC_DIR=src
R_PACKAGE_DIR=rpackage
R_SCRIPT_DIR=$(R_PACKAGE_DIR)/R
JAR=$(R_PACKAGE_DIR)/inst/java/cloneid.jar
TAR_FILE=cloneid_1.2.1.tar.gz
GRADLE=./gradlew

JAVA_SOURCES=$(shell find $(JAVA_SRC_DIR) -type f -name "*.java")
R_SCRIPTS=$(shell find $(R_SCRIPT_DIR) -type f -name "*.R")

all: $(TAR_FILE)

$(JAR): $(JAVA_SOURCES)
	scripts/updateGradle.sh
	$(GRADLE) uberJar
	cp build/libs/cloneid.jar $(JAR)

$(TAR_FILE): $(JAR) $(R_SCRIPTS)
	R CMD build $(R_PACKAGE_DIR)
	R CMD INSTALL $(TAR_FILE)

test: $(TAR_FILE)
	Rscript ../test/performance/bin/R/unit-test-0/m3.R

clean:
	$(GRADLE) clean
	rm -f $(R_PACKAGE_DIR)/inst/java/cloneid.jar
	rm -f $(TAR_FILE)
	rm -rf $(R_PACKAGE_DIR).Rcheck

.PHONY: all test clean
