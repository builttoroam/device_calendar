import Flutter
import UIKit
import EventKit

public class SwiftDeviceCalendarPlugin: NSObject, FlutterPlugin {
    struct Calendar: Codable {
        let id: String;
        let name: String;
    }
    
    static let channelName = "plugins.builttoroam.com/device_calendar";
    let eventStore = EKEventStore();
    let retrieveCalendarsMethod = "retrieveCalendars";
    let retrieveEventsMethod = "retrieveEvents";
    let calendarIdArgument = "calendarId";
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = SwiftDeviceCalendarPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case retrieveCalendarsMethod:
            requestPermission(completion: {
                (accessGranted: Bool) in
                do {
                    let ekCalendars = self.eventStore.calendars(for: .event)
                    var calendars = [Calendar]()
                    for ekCalendar in ekCalendars {
                        let calendar = Calendar(id: ekCalendar.calendarIdentifier, name: ekCalendar.title)
                        calendars.append(calendar)
                    }
                    
                    let jsonEncoder = JSONEncoder();
                    let jsonData = try jsonEncoder.encode(calendars)
                    
                    let jsonString = String(data: jsonData, encoding: .utf8)
                    result(jsonString)
                } catch {
                    result(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
                }
            })
        case retrieveEventsMethod:
            requestPermission(completion: {
                (accessGranted: Bool) in
                let arguments = call.arguments as! Dictionary<String, AnyObject>;
                let calendarId = arguments[self.calendarIdArgument] as! String;
                let ekCalendar = self.eventStore.calendar(withIdentifier: calendarId)
            })
        default:
            result(FlutterMethodNotImplemented)
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
