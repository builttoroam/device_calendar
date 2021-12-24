deviceId=$(xcrun simctl create builtToRoamCalendarTest "iPhone 13" 2> /dev/null | tail -1)
echo "Created device: $deviceId, booting..."
xcrun simctl boot $deviceId
xcrun simctl privacy $deviceId grant calendar com.builttoroam.deviceCalendarExample00
echo "Running tests..."
flutter drive --driver=integration_test/integration_test.dart --target=integration_test/app_test.dart -d $deviceId
echo "Removing up device: $deviceId"
xcrun simctl delete $deviceId