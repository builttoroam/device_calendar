# Use: integration_test/ios.sh 
#
# Executes the device_calendar integration test for iOS
# This script creates and starts a new iOS simulator, grants calendar permission 
# to the app then runs the integration tests and finally deletes the simulator.
# Prerequisites: Xcode, Xcode Command Line Tools, Xcode iOS Simulator
#
# Success - "All tests passed." is printed to the console
#
deviceId=$(xcrun simctl create builtToRoamCalendarTest "iPhone 13" 2> /dev/null | tail -1)
echo "Created device: $deviceId, booting..."
xcrun simctl boot $deviceId
xcrun simctl privacy $deviceId grant calendar com.builttoroam.deviceCalendarExample00
echo "Running tests..."
flutter drive --driver=integration_test/integration_test.dart --target=integration_test/app_test.dart -d $deviceId
echo "Removing device: $deviceId"
xcrun simctl delete $deviceId