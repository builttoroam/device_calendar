import Flutter
import UIKit
import EventKit

public class SwiftDeviceCalendarPlugin: NSObject, FlutterPlugin {
    struct Calendar: Codable {
        let id: String;
        let name: String;
    }
    
    struct Event: Codable {
        let id: String;
        let title: String;
        let start: Int;
        let end: Int;
    }
    
    static let channelName = "plugins.builttoroam.com/device_calendar";
    let eventStore = EKEventStore();
    let retrieveCalendarsMethod = "retrieveCalendars";
    let retrieveEventsMethod = "retrieveEvents";
    let calendarIdArgument = "calendarId";
    let startDateArgument = "startDate";
    let endDateArgument = "endDate";
    
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
                
                let ekCalendars = self.eventStore.calendars(for: .event)
                var calendars = [Calendar]()
                for ekCalendar in ekCalendars {
                    let calendar = Calendar(id: ekCalendar.calendarIdentifier, name: ekCalendar.title)
                    calendars.append(calendar)
                }
                
                self.encodeJsonAndFinish(codable: calendars, result: result)
            })
        case retrieveEventsMethod:
            requestPermission(completion: {
                (accessGranted: Bool) in
                let arguments = call.arguments as! Dictionary<String, AnyObject>;
                let calendarId = arguments[self.calendarIdArgument] as! String;
                let startDateMillisecondsSinceEpoch = arguments[self.startDateArgument] as! NSNumber
                let endDateDateMillisecondsSinceEpoch = arguments[self.endDateArgument] as! NSNumber
                let startDate = Date (timeIntervalSince1970: startDateMillisecondsSinceEpoch.doubleValue / 1000.0)
                let endDate = Date (timeIntervalSince1970: endDateDateMillisecondsSinceEpoch.doubleValue / 1000.0)
                let ekCalendar = self.eventStore.calendar(withIdentifier: calendarId)
                let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [ekCalendar!])
                let ekEvents = self.eventStore.events(matching: predicate)
                var events = [Event]()
                for ekEvent in ekEvents {
                    let event = Event(id: ekEvent.eventIdentifier, title: ekEvent.title, start: Int(ekEvent.startDate.timeIntervalSince1970) * 1000, end: Int(ekEvent.endDate.timeIntervalSince1970) * 1000)
                    events.append(event)
                }
                
                self.encodeJsonAndFinish(codable: events, result: result)
                
            })
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func encodeJsonAndFinish<T: Codable>(codable: T, result: @escaping FlutterResult) {
        do {
            let jsonEncoder = JSONEncoder();
            let jsonData = try jsonEncoder.encode(codable)
            
            let jsonString = String(data: jsonData, encoding: .utf8)
            result(jsonString)
        } catch {
            result(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
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
