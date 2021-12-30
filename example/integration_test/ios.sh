# Use: integration_test/ios.sh [device_id]
#
# Executes the device_calendar integration test for iOS
#
# When run without a [device_id] argument, it will run the test on a simulator:
# This script creates and starts a new iOS simulator, grants calendar permission 
# to the app then runs the integration tests and finally deletes the simulator.
#
# When run with a [device_id] argument, it will run the test on the device with that id
# and assumes that the device is already running.
#
# Prerequisites: Xcode, Xcode Command Line Tools, Xcode iOS Simulator
#
# Success - "All tests passed." is printed to the console
#
if [ $# -gt 1 ]; then
    echo "Usage: $0 [device_id]"
    exit 1
fi
if [ $# -eq 0 ]
  then
    deviceId=$(xcrun simctl create builtToRoamCalendarTest "iPhone 13" 2> /dev/null | tail -1)
    echo "Created device: $deviceId, booting..."
    xcrun simctl boot $deviceId
    xcrun simctl privacy $deviceId grant calendar com.builttoroam.deviceCalendarExample00
    echo "Running tests..."
    flutter drive --driver=integration_test/integration_test.dart --target=integration_test/app_test.dart -d $deviceId
    echo "Removing device: $deviceId"
    xcrun simctl delete $deviceId
else
    echo "This test needs calendar permission for the app, watch the device and grant manually if required."
    deviceId=$1
    flutter drive --driver=integration_test/integration_test.dart --target=integration_test/app_test.dart -d $deviceId
fi
