#!/bin/bash

GRADLE_WRAPPER_FILE="gradle/wrapper/gradle-wrapper.properties"
# GRADLE_WRAPPER_FILE="gradle-wrapper.properties"
OLD_VERSION="6.5.1"
NEW_VERSION="8.9"
BUILD_GRADLE_FILE="build.gradle"

# Check if the gradle-wrapper.properties file exists
if [ ! -f "$GRADLE_WRAPPER_FILE" ]; then
    echo "Error: $GRADLE_WRAPPER_FILE not found."
    exit 1
fi

# Update the Gradle version
if grep -q "$OLD_VERSION" "$GRADLE_WRAPPER_FILE"; then
    sed -i.bak -e "s/$OLD_VERSION/$NEW_VERSION/" -e "s/https.*distributions\///" "$GRADLE_WRAPPER_FILE"
    echo "Gradle version updated from $OLD_VERSION to $NEW_VERSION in $GRADLE_WRAPPER_FILE."
    # Optionally, remove the backup file created by sed
    rm -f "${GRADLE_WRAPPER_FILE}.bak"
else
    echo "Gradle version $OLD_VERSION not found in $GRADLE_WRAPPER_FILE. No changes made."
fi


# Check if the build.gradle file exists
if [ ! -f "$BUILD_GRADLE_FILE" ]; then
    echo "Error: $BUILD_GRADLE_FILE not found."
    exit 1
fi

# Add DuplicatesStrategy if not present
if ! grep -q 'DuplicatesStrategy' "$BUILD_GRADLE_FILE"; then
    sed -i.bak \
        -e 's/baseName/\/\/ MOVING TO GRADLE 8.9 \/\/ baseName/' \
        -e 's/archiveClassifier/duplicatesStrategy = DuplicatesStrategy.EXCLUDE\n    archiveClassifier/' \
        "$BUILD_GRADLE_FILE"
    echo "Updated DuplicatesStrategy in $BUILD_GRADLE_FILE."
    # Optionally, remove the backup file created by sed
    rm -f "${BUILD_GRADLE_FILE}.bak"
else
    echo "DuplicatesStrategy already present in $BUILD_GRADLE_FILE. No changes made."
fi
