import Flutter
import UIKit
import EventKit

public class SwiftDeviceCalendarPlugin: NSObject, FlutterPlugin {
    static let channelName = "plugins.builttoroam.com/device_calendar";
    let eventStore = EKEventStore();
    let retrieveCalendarsMethodName = "retrieveCalendars";
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = SwiftDeviceCalendarPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method == retrieveCalendarsMethodName) {
            eventStore.calendars(for: .event)
        }
    }
    
    private func requestPermission(completion: @escaping (Bool) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)
        if(status != EKAuthorizationStatus.authorized) {
            eventStore.requestAccess(to: .event, completion: {
                (accessGranted: Bool, error: Error?) in
                completion(accessGranted)
            })
        }
        completion(true)
    }
}
