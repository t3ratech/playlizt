#!/bin/bash
# Install Playwright browsers for UI testing

cd "$(dirname "$0")"

echo "Installing Playwright browsers..."
../gradlew :playlizt-ui-tests:installPlaywrightBrowsers
exit $?
