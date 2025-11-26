#!/bin/bash
# Install Playwright browsers for UI testing

cd "$(dirname "$0")"

echo "Installing Playwright browsers..."
../gradlew :playlizt-ui-tests:compileTestJava

# Find Playwright driver jar
PLAYWRIGHT_JAR=$(find ~/.gradle/caches -name "driver-*.jar" | grep "com.microsoft.playwright" | head -1)

if [ -z "$PLAYWRIGHT_JAR" ]; then
    echo "Error: Playwright driver jar not found. Building project first..."
    ../gradlew :playlizt-ui-tests:build
    PLAYWRIGHT_JAR=$(find ~/.gradle/caches -name "driver-*.jar" | grep "com.microsoft.playwright" | head -1)
fi

echo "Using Playwright jar: $PLAYWRIGHT_JAR"

# Install browsers using Java directly
java -cp "$PLAYWRIGHT_JAR" com.microsoft.playwright.CLI install chromium

echo "✓ Playwright Chromium browser installed"
