import Flutter
import UIKit
import EventKit

public class SwiftDeviceCalendarPlugin: NSObject, FlutterPlugin {
    struct Calendar: Codable {
        let id: String
        let name: String
    }
    
    struct Event: Codable {
        let id: String
        let title: String
        let description: String?
        let start: Int
        let end: Int
    }
    
    static let channelName = "plugins.builttoroam.com/device_calendar"
    // Note: this is placeholder error codes and messages until they have been finalised across both platforms
    let notFoundErrorCode = "404";
    let genericError = "500"
    let unauthorizedErrorCode = "401"
    let unauthorizedErrorMessage = "The user has not allowed this application to modify their calendar"
    let calendarNotFoundErrorMessage = "The calendar with the specified id could not be found"
    let eventNotFoundErrorMessage = "The event with the specified id could not be found"
    let eventStore = EKEventStore()
    let retrieveCalendarsMethod = "retrieveCalendars"
    let retrieveEventsMethod = "retrieveEvents"
    let createOrUpdateEventMethod = "createOrUpdateEvent"
    let deleteEventMethod = "deleteEvent"
    let calendarIdArgument = "calendarId"
    let startDateArgument = "startDate"
    let endDateArgument = "endDate"
    let eventIdArgument = "eventId"
    let eventTitleArgument = "eventTitle"
    let eventDescriptionArgument = "eventDescription";
    let eventStartDateArgument =  "eventStartDate"
    let eventEndDateArgument = "eventEndDate"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = SwiftDeviceCalendarPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case retrieveCalendarsMethod:
            requestPermission(completion: {
                (accessGranted) in
                if(accessGranted) {
                    let ekCalendars = self.eventStore.calendars(for: .event)
                    var calendars = [Calendar]()
                    for ekCalendar in ekCalendars {
                        let calendar = Calendar(id: ekCalendar.calendarIdentifier, name: ekCalendar.title)
                        calendars.append(calendar)
                    }
                    
                    self.encodeJsonAndFinish(codable: calendars, result: result)
                } else {
                    self.finishWithUnauthorizedError(result: result)
                }
            })
        case retrieveEventsMethod:
            requestPermission(completion: {
                (accessGranted) in
                if(accessGranted) {
                    let arguments = call.arguments as! Dictionary<String, AnyObject>
                    let calendarId = arguments[self.calendarIdArgument] as! String
                    let startDateMillisecondsSinceEpoch = arguments[self.startDateArgument] as! NSNumber
                    let endDateDateMillisecondsSinceEpoch = arguments[self.endDateArgument] as! NSNumber
                    let startDate = Date (timeIntervalSince1970: startDateMillisecondsSinceEpoch.doubleValue / 1000.0)
                    let endDate = Date (timeIntervalSince1970: endDateDateMillisecondsSinceEpoch.doubleValue / 1000.0)
                    let ekCalendar = self.eventStore.calendar(withIdentifier: calendarId)
                    let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [ekCalendar!])
                    let ekEvents = self.eventStore.events(matching: predicate)
                    var events = [Event]()
                    for ekEvent in ekEvents {
                        let event = Event(id: ekEvent.eventIdentifier, title: ekEvent.title, description: ekEvent.notes, start: Int(ekEvent.startDate.timeIntervalSince1970) * 1000, end: Int(ekEvent.endDate.timeIntervalSince1970) * 1000)
                        events.append(event)
                    }
                    
                    self.encodeJsonAndFinish(codable: events, result: result)
                } else {
                    self.finishWithUnauthorizedError(result: result)
                }
                
            })
        case createOrUpdateEventMethod:
            requestPermission(completion: {
                (accessGranted) in
                if (accessGranted) {
                    let arguments = call.arguments as! Dictionary<String, AnyObject>
                    let calendarId = arguments[self.calendarIdArgument] as! String
                    let eventId = arguments[self.eventIdArgument] as? String
                    let startDateMillisecondsSinceEpoch = arguments[self.eventStartDateArgument] as! NSNumber
                    let endDateDateMillisecondsSinceEpoch = arguments[self.eventEndDateArgument] as! NSNumber
                    let startDate = Date (timeIntervalSince1970: startDateMillisecondsSinceEpoch.doubleValue / 1000.0)
                    let endDate = Date (timeIntervalSince1970: endDateDateMillisecondsSinceEpoch.doubleValue / 1000.0)
                    let title = arguments[self.eventTitleArgument] as! String
                    let description = arguments[self.eventDescriptionArgument] as! String
                    let ekCalendar = self.eventStore.calendar(withIdentifier: calendarId)
                    if (ekCalendar == nil) {
                        self.finishWithCalendarNotFoundError(result: result)
                        return
                    }
                    
                    var ekEvent: EKEvent?
                    if(eventId == nil) {
                        ekEvent = EKEvent.init(eventStore: self.eventStore)
                    } else {
                        ekEvent = self.eventStore.event(withIdentifier: eventId!)
                        if(ekEvent == nil) {
                            self.finishWithEventNotFoundError(result: result)
                            return
                        }
                    }
                    ekEvent!.title = title
                    ekEvent!.notes = description
                    ekEvent!.startDate = startDate
                    ekEvent!.endDate = endDate
                    ekEvent!.calendar = ekCalendar
                    do {
                        try self.eventStore.save(ekEvent!, span: EKSpan.futureEvents)
                        result(ekEvent!.eventIdentifier)
                    } catch {
                        self.eventStore.reset()
                        result(FlutterError(code: self.genericError, message: error.localizedDescription, details: nil))
                    }
                } else {
                    self.finishWithUnauthorizedError(result: result)
                }
            })
        case deleteEventMethod:
            requestPermission(completion: {
                (accessGranted) in
                if(accessGranted) {
                    let arguments = call.arguments as! Dictionary<String, AnyObject>
                    let calendarId = arguments[self.calendarIdArgument] as! String
                    let eventId = arguments[self.eventIdArgument] as! String
                    let ekCalendar = self.eventStore.calendar(withIdentifier: calendarId)
                    if (ekCalendar == nil) {
                        self.finishWithCalendarNotFoundError(result: result)
                        return;
                    }
                    let ekEvent = self.eventStore.event(withIdentifier: eventId)
                    if (ekEvent == nil) {
                        self.finishWithEventNotFoundError(result: result)
                        return
                    }
                    
                    do {
                        try self.eventStore.remove(ekEvent!, span: .thisEvent)
                        result(true)
                    } catch {
                        self.eventStore.reset()
                        result(FlutterError(code: self.genericError, message: error.localizedDescription, details: nil))
                    }
                } else {
                    self.finishWithUnauthorizedError(result: result)
                }
            })
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func finishWithUnauthorizedError(result: @escaping FlutterResult) {
        result(FlutterError(code:self.unauthorizedErrorCode, message: self.unauthorizedErrorMessage, details: nil))
    }
    
    private func finishWithCalendarNotFoundError(result: @escaping FlutterResult) {
        result(FlutterError(code:self.notFoundErrorCode, message: self.calendarNotFoundErrorMessage, details: nil))
    }
    
    private func finishWithEventNotFoundError(result: @escaping FlutterResult) {
        result(FlutterError(code:self.notFoundErrorCode, message: self.eventNotFoundErrorMessage, details: nil))
    }
    
    private func encodeJsonAndFinish<T: Codable>(codable: T, result: @escaping FlutterResult) {
        do {
            let jsonEncoder = JSONEncoder();
            let jsonData = try jsonEncoder.encode(codable)
            let jsonString = String(data: jsonData, encoding: .utf8)
            result(jsonString)
        } catch {
            result(FlutterError(code: genericError, message: error.localizedDescription, details: nil))
        }
    }
    
    private func requestPermission(completion: @escaping (Bool) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)
        if(status != EKAuthorizationStatus.authorized) {
            eventStore.requestAccess(to: .event, completion: {
                (accessGranted: Bool, error: Error?) in
                completion(accessGranted)
            })
            return
        }
        completion(true)
    }
}
