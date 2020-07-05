#import "DeviceCalendarPlugin.h"
#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>
#import "models/Calendar.h"
#import "models/RecurrenceRule.h"
#import "models/Event.h"
#import "models/Attendee.h"
#import "models/Reminder.h"
#import "models/Department.h"
#import "Date+Utilities.h"
#import "UIColor+Utilities.h"
#import <objc/runtime.h>
#import "Availability.h"

@implementation DeviceCalendarPlugin
NSString *streamName = @"calendarChangeEvent/stream";
NSString *methodChannelName = @"plugins.builttoroam.com/device_calendar";
NSString *notFoundErrorCode = @"404";
NSString *notAllowed = @"405";
NSString *genericError = @"500";
NSString *unauthorizedErrorCode = @"401";
NSString *unauthorizedErrorMessage = @"The user has not allowed this application to modify their calendar(s)";
NSString *calendarNotFoundErrorMessageFormat = @"The calendar with the ID %@ could not be found";
NSString *calendarReadOnlyErrorMessageFormat = @"Calendar with ID %@ is read-only";
NSString *eventNotFoundErrorMessageFormat = @"The event with the ID %@ could not be found";
NSString *requestPermissionsMethod = @"requestPermissions";
NSString *hasPermissionsMethod = @"hasPermissions";
NSString *retrieveSourcesMethod = @"retrieveSources";
NSString *retrieveCalendarsMethod = @"retrieveCalendars";
NSString *retrieveEventsMethod = @"retrieveEvents";
NSString *createCalendarMethod = @"createCalendar";
NSString *createOrUpdateEventMethod = @"createOrUpdateEvent";
NSString *deleteEventMethod = @"deleteEvent";
NSString *deleteEventInstanceMethod = @"deleteEventInstance";
NSString *calendarIdArgument = @"calendarId";
NSString *startDateArgument = @"startDate";
NSString *endDateArgument = @"endDate";
NSString *eventIdArgument = @"eventId";
NSString *eventIdsArgument = @"eventIds";
NSString *eventTitleArgument = @"eventTitle";
NSString *eventDescriptionArgument = @"eventDescription";
NSString *eventAllDayArgument = @"eventAllDay";
NSString *eventStartDateArgument =  @"eventStartDate";
NSString *eventEndDateArgument = @"eventEndDate";
NSString *eventLocationArgument = @"eventLocation";
NSString *attendeesArgument = @"attendees";
NSString *recurrenceRuleArgument = @"recurrenceRule";
NSString *recurrenceFrequencyArgument = @"recurrenceFrequency";
NSString *totalOccurrencesArgument = @"totalOccurrences";
NSString *intervalArgument = @"interval";
NSString *daysOfWeekArgument = @"daysOfWeek";
NSString *daysOfMonthArgument = @"daysOfMonth";
NSString *monthOfYearArgument = @"monthsOfYear";
NSString *weeksOfYearArgument = @"weeksOfYear";
NSString *weekOfMonthArgument = @"weekOfMonth";
NSString *nameArgument = @"nameArgument";
NSString *emailAddressArgument = @"emailAddress";
NSString *roleArgument = @"role";
NSString *remindersArgument = @"reminders";
NSString *minutesArgument = @"minutes";
NSString *followingInstancesArgument = @"followingInstances";
NSString *calendarNameArgument = @"calendarName";
NSString *calendarColorArgument = @"calendarColor";
NSString *eventURLArgument = @"eventURL";
NSString *availabilityArgument = @"availability";
NSMutableArray *validFrequencyTypes;
EKEventStore *eventStore;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName: methodChannelName
                                     binaryMessenger:[registrar messenger]];
    eventStore = [[EKEventStore alloc] init];
    validFrequencyTypes = [NSMutableArray new];
    [validFrequencyTypes addObject: [[NSNumber alloc] initWithInt:EKRecurrenceFrequencyDaily]];
    [validFrequencyTypes addObject: [[NSNumber alloc] initWithInt:EKRecurrenceFrequencyWeekly]];
    [validFrequencyTypes addObject: [[NSNumber alloc] initWithInt:EKRecurrenceFrequencyMonthly]];
    [validFrequencyTypes addObject: [[NSNumber alloc] initWithInt:EKRecurrenceFrequencyYearly]];
    DeviceCalendarPlugin* instance = [[DeviceCalendarPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *method = call.method;
    if ([method isEqualToString: requestPermissionsMethod]) {
        [self requestPermissions:nil result:result];
        return;
    }
    else if([method isEqualToString: hasPermissionsMethod]) {
        [self hasPermissions:nil result:result];
        return;
    }
    else if ([method isEqualToString: retrieveCalendarsMethod]) {
        [self retrieveCalendars:nil result:result];
        return;
    }
    else if ([method isEqualToString: retrieveEventsMethod]) {
        [self retrieveEvents:call result:result];
        return;
    }
    else if ([method isEqualToString: createOrUpdateEventMethod]) {
        [self createOrUpdateEvent:call result:result];
        return;
    }
    else if ([method isEqualToString: deleteEventMethod]) {
        [self deleteEvent:call result:result];
        return;
    }
    else if ([method isEqualToString:deleteEventInstanceMethod]) {
        [self deleteEvent:call result:result];
        return;
    }
    else if ([method isEqualToString:createCalendarMethod]) {
        [self createCalendar:call result:result];
        return;
    }
    else
        result(FlutterMethodNotImplemented);
}

-(void)hasPermissions:(id)args result:(FlutterResult)result {
    result([NSNumber numberWithBool:[self hasEventPermissions]]);
}

-(void)createCalendar:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSDictionary *arguments = call.arguments;
    EKCalendar *calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:eventStore];
    calendar.title = [arguments valueForKey:calendarNameArgument];
    NSString *calendarColor = [arguments valueForKey:calendarColorArgument];
    NSMutableArray *localSources = [NSMutableArray new];
    NSError *error = nil;
    if (calendarColor != nil) {
        calendar.CGColor = [[self colorFromHexString:calendarColor] CGColor];
    }else {
        calendar.CGColor = [[[UIColor alloc] initWithRed:255 green:0 blue:0 alpha:0] CGColor];
    }
    for (EKSource *ekSource in eventStore.sources) {
        if (ekSource.sourceType == EKSourceTypeLocal) {
            [localSources addObject:ekSource];
        }
    }
    if ([localSources count]) {
        calendar.source = [localSources firstObject];
        [eventStore saveCalendar:calendar commit:YES error:&error];
    } else {
        result([FlutterError errorWithCode:genericError message: @"Local calendar was not found." details:nil ]);
    }
    if (error == nil) {
        result([calendar calendarIdentifier]);
    } else {
        [eventStore reset];
        result([FlutterError errorWithCode:genericError message: [error localizedDescription] details:nil ]);
    }
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 24)/255.0 green:((rgbValue & 0xFF00) >> 16)/255.0 blue:((rgbValue & 0x0000ff00) >> 8)/255.0 alpha: (rgbValue & 0x000000ff) / 255];
}

-(void)retrieveCalendars:(id)args result:(FlutterResult)result{
    Department *department = [Department new];
    department.calendars = [NSMutableArray new];
    [self checkPermissionsThenExecute:nil permissionsGrantedAction:^{
        NSArray *ekcalendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
        EKCalendar *defaultCalendar = [eventStore defaultCalendarForNewEvents];
        for (EKCalendar* ekCalendar in ekcalendars) {
            
            Calendar *calendar = [Calendar new];
            calendar.id = ekCalendar.calendarIdentifier;
            calendar.name = ekCalendar.title;
            calendar.isReadOnly = !ekCalendar.allowsContentModifications;
            calendar.isDefault = [defaultCalendar calendarIdentifier] == [ekCalendar calendarIdentifier];
            calendar.color = [[[[UIColor alloc] initWithCGColor:[ekCalendar CGColor]] rgb] intValue];
            calendar.accountName = [[ekCalendar source] title];
            calendar.accountType = [self getAccountType:[[ekCalendar source]sourceType]];
            [department.calendars addObject:calendar];
        }
        [self encodeJsonAndFinish:department result:result];
    } result:result];
}

-(NSString*)getAccountType:(EKSourceType)sourceType {
    if (sourceType == EKSourceTypeLocal) {
        return @"Local";
    }else if(sourceType == EKSourceTypeExchange) {
        return @"Exchange";
    }else if(sourceType == EKSourceTypeCalDAV) {
        return @"CalDAV";
    }else if(sourceType == EKSourceTypeMobileMe) {
        return @"MobileMe";
    }else if(sourceType == EKSourceTypeSubscribed) {
        return @"Subscribed";
    }else if(sourceType == EKSourceTypeBirthdays) {
        return @"Birthdays";
    } else {
        return @"Unknown";
    }
}

-(void)retrieveEvents:(FlutterMethodCall *)call result:(FlutterResult)result {
    [self checkPermissionsThenExecute:nil permissionsGrantedAction:^{
        NSDictionary *arguments = call.arguments;
        NSString *calendarId = [arguments valueForKey:calendarIdArgument];
        NSNumber *startDateMillisecondsSinceEpoch = [arguments valueForKey:startDateArgument];
        NSNumber *endDateMillisecondsSinceEpoch = [arguments valueForKey:endDateArgument];
        NSArray *_Nullable eventIds = [arguments valueForKey:eventIdsArgument];
        Department *department = [[Department alloc] init];
        department.events = [NSMutableArray new];
        NSMutableArray *events = [NSMutableArray new];
        BOOL specifiedStartEndDates = startDateMillisecondsSinceEpoch != nil && endDateMillisecondsSinceEpoch != nil;
        if (specifiedStartEndDates) {
            NSDate *startDate = [[NSDate alloc] initWithTimeIntervalSince1970: [startDateMillisecondsSinceEpoch doubleValue] / 1000.0];
            NSDate *endDate = [[NSDate alloc] initWithTimeIntervalSince1970: [endDateMillisecondsSinceEpoch doubleValue] / 1000.0];
            EKCalendar *ekCalendar = [eventStore calendarWithIdentifier: calendarId];
            NSMutableArray *calendars = [NSMutableArray new];
            [calendars addObject:ekCalendar];
            NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:calendars];
            NSArray *ekEvents = [eventStore eventsMatchingPredicate:predicate];
            for (EKEvent* ekEvent in ekEvents) {
                Event *event = [self createEventFromEkEvent:calendarId event:ekEvent];
                [events addObject:event];
            }
        }
        
        if (eventIds == [NSNull null]) {
            for (Event *event in events) {
                [department.events addObject:event];
            }
            [self encodeJsonAndFinish:department result:result];
            return;
        }
        if (specifiedStartEndDates) {
            for (Event *event in events) {
                if (event.calendarId == calendarId && [eventIds containsObject:event.eventId]) {
                    [department.events addObject:event];
                }
            }
            [self encodeJsonAndFinish:department result:result];
            return;
        }
        for (NSString *eventId in eventIds) {
            EKEvent *ekEvent = [eventStore eventWithIdentifier:eventId];
            if (ekEvent != nil) {
                continue;
            }
            Event *event = [self createEventFromEkEvent:calendarId event:ekEvent];
            [department.events addObject:event];
        }
        [self encodeJsonAndFinish:department result:result];
    } result: result];
}

-(Event*)createEventFromEkEvent: (NSString *)calendarId event:(EKEvent *)ekEvent {
    NSMutableArray *attendees = [NSMutableArray new];
    if ([ekEvent attendees] != nil) {
        for(EKParticipant *ekParticipant in [ekEvent attendees]) {
            Attendee *attendee = [self convertEkParticipantToAttendee:ekParticipant];
            if (attendee == nil) {
                continue;
            }
            [attendees addObject:attendee];
        }
    }
    
    NSMutableArray *reminders = [NSMutableArray new];
    if ([ekEvent alarms] != nil) {
        for (EKAlarm *alarm in [ekEvent alarms]) {
            Reminder *reminder = [Reminder new];
            reminder.minutes = -[alarm relativeOffset]/60;
            [reminders addObject:reminder];
        }
    }
    RecurrenceRule *recurrenceRule = [self parseEKRecurrenceRules:ekEvent];
    Event *event = [Event new];
    event.eventId = [ekEvent eventIdentifier];
    event.calendarId = calendarId;
    if (ekEvent.title == nil) {
        event.title = @"New title";
    } else {
        event.title = [ekEvent title];
    }
    event.description = [ekEvent notes];
    event.start = [[[NSNumber alloc] initWithFloat:[[ekEvent startDate] millisecondsSinceEpoch]] integerValue];
    event.end = [[[NSNumber alloc] initWithFloat:[[ekEvent endDate] millisecondsSinceEpoch]] integerValue];
    event.allDay = [ekEvent isAllDay];
    event.attendees = attendees;
    event.location = [ekEvent location];
    event.url = [[ekEvent URL] absoluteString];
    event.recurrenceRule = recurrenceRule;
    event.organizer = [self convertEkParticipantToAttendee:[ekEvent organizer]];
    event.reminders = reminders;
    event.availability = [self convertEkEventAvailability:[ekEvent availability]];
    return event;
}

-(NSString*) convertEkEventAvailability: (EKEventAvailability)ekEventAvailability {
    if (ekEventAvailability == EKEventAvailabilityBusy) {
        return @"BUSY";
    } else if (ekEventAvailability == EKEventAvailabilityFree) {
        return @"FREE";
    } else if (ekEventAvailability == EKEventAvailabilityTentative) {
        return @"TENTATIVE";
    } else if (ekEventAvailability == EKEventAvailabilityUnavailable) {
        return @"UNAVAILABLE";
    } else {
        return nil;
    }
}

-(Attendee*)convertEkParticipantToAttendee: (EKParticipant *)ekParticipant {
    if (ekParticipant == nil || [[ekParticipant URL] resourceSpecifier] == nil) {
        return nil;
    }
    Attendee *attendee = [Attendee new];
    attendee.name = [ekParticipant name];
    attendee.emailAddress = [[ekParticipant URL] resourceSpecifier];
    attendee.role = [ekParticipant participantRole];
    return attendee;
}

-(RecurrenceRule *)parseEKRecurrenceRules:(EKEvent *)ekEvent {
    RecurrenceRule *recurrenceRule = [RecurrenceRule new];
    if ([ekEvent hasRecurrenceRules]) {
        EKRecurrenceRule *ekRecurrenceRule = [[ekEvent recurrenceRules] firstObject];
        NSInteger frequency;
        switch ([ekRecurrenceRule frequency]) {
            case EKRecurrenceFrequencyDaily:
                frequency = 0;
                break;
            case EKRecurrenceFrequencyWeekly:
                frequency = 1;
                break;
            case EKRecurrenceFrequencyMonthly:
                frequency = 2;
                break;
            case EKRecurrenceFrequencyYearly:
                frequency = 3;
                break;
            default:
                frequency = 0;
                break;
        }
        
        NSNumber *totalOccurrences;
        NSNumber *endDate;
        if([[ekRecurrenceRule recurrenceEnd] occurrenceCount] != 0 && [[ekRecurrenceRule recurrenceEnd] occurrenceCount] != 0){
            totalOccurrences = [[NSNumber alloc] initWithUnsignedInteger:[[ekRecurrenceRule recurrenceEnd] occurrenceCount]];
        }
        float endDateMs = [[[ekRecurrenceRule recurrenceEnd] endDate] millisecondsSinceEpoch];
        if (endDateMs) {
            endDate = [[NSNumber alloc] initWithFloat:endDateMs];
        }
        NSMutableArray *daysOfWeek = [NSMutableArray new];
        NSInteger weekOfMonth = [[[ekRecurrenceRule setPositions] firstObject] intValue];
        if ([ekRecurrenceRule daysOfTheWeek] != nil && [[ekRecurrenceRule daysOfTheWeek] count] != 0) {
            daysOfWeek = [NSMutableArray new];
            for (EKRecurrenceDayOfWeek *dayOfWeek in [ekRecurrenceRule daysOfTheWeek]) {
                [daysOfWeek addObject: [[NSNumber alloc] initWithInt:[dayOfWeek dayOfTheWeek] - 1]];
                if (weekOfMonth == 0) {
                    weekOfMonth = [dayOfWeek weekNumber];
                }
            }
        }
        
        NSInteger dayOfMonth = [[[ekRecurrenceRule daysOfTheMonth] firstObject] intValue];
        NSInteger monthOfYear = [[[ekRecurrenceRule monthsOfTheYear] firstObject] intValue];
        
        if (ekRecurrenceRule.frequency == EKRecurrenceFrequencyYearly
            && weekOfMonth == 0 && dayOfMonth == 0 && monthOfYear == 0) {
            NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
            dateFormater.dateFormat = @"d";
            dayOfMonth = [[dateFormater stringFromDate:ekEvent.startDate] intValue];
            dateFormater.dateFormat = @"M";
            monthOfYear = [[dateFormater stringFromDate:ekEvent.startDate] intValue];
        }

        recurrenceRule.recurrenceFrequency = frequency;
        recurrenceRule.totalOccurrences = totalOccurrences;
        recurrenceRule.interval = [ekRecurrenceRule interval];
        recurrenceRule.endDate = endDate;
        recurrenceRule.daysOfWeek = daysOfWeek;
        recurrenceRule.daysOfMonth = dayOfMonth;
        recurrenceRule.monthsOfYear = monthOfYear;
        recurrenceRule.weekOfMonth = weekOfMonth;
    }
    return recurrenceRule;
}

-(EKEventAvailability)setAvailability: (NSDictionary*)arguments {
    NSString *availabilityValue = [arguments valueForKey:availabilityArgument];
    if ([availabilityValue isEqualToString: @"BUSY"]) {
        return EKEventAvailabilityBusy;
    } else if ([availabilityValue isEqualToString: @"FREE"]) {
        return EKEventAvailabilityFree;
    } else if ([availabilityValue isEqualToString: @"TENTATIVE"]) {
        return EKEventAvailabilityTentative;
    } else {
        return EKEventAvailabilityUnavailable;
    }
}

-(NSArray*) createEKRecurrenceRules: (NSDictionary*)arguments {
    NSDictionary *recurrenceRuleArguments = [arguments valueForKey:recurrenceRuleArgument];
    if ([recurrenceRuleArguments isEqual:[NSNull null]]) {
        return nil;
    }
    NSNumber *recurrenceFrequencyIndex = [recurrenceRuleArguments valueForKey:recurrenceFrequencyArgument];
    NSInteger totalOccurrences = [[recurrenceRuleArguments valueForKey:totalOccurrencesArgument] integerValue];
    NSInteger interval = -1;
    interval = [[recurrenceRuleArguments valueForKey:intervalArgument] integerValue];
    NSInteger recurrenceInterval = 1;
    NSNumber *endDate = [recurrenceRuleArguments valueForKey:endDateArgument];
    EKRecurrenceFrequency namedFrequency = [[validFrequencyTypes objectAtIndex:[recurrenceFrequencyIndex intValue]] integerValue];
    EKRecurrenceEnd *recurrenceEnd;
            
    if (endDate != nil) {
        recurrenceEnd = [EKRecurrenceEnd recurrenceEndWithEndDate: [[NSDate alloc] initWithTimeIntervalSince1970: [endDate doubleValue]]];
    } else if (totalOccurrences > 0){
        recurrenceEnd = [EKRecurrenceEnd recurrenceEndWithOccurrenceCount: totalOccurrences];
    }
    if (interval != -1 && interval > 1) {
        recurrenceInterval = interval;
    }
    
    NSArray *daysOfTheWeekIndices = [recurrenceRuleArguments valueForKey:daysOfWeekArgument];
    NSMutableArray *daysOfWeek;
    
    if (daysOfWeek != nil && [daysOfTheWeekIndices count] == 0) {
        daysOfWeek = [NSMutableArray new];
        for (NSNumber *dayOfWeekIndex in daysOfTheWeekIndices) {
            NSNumber *weekOfMonth = [recurrenceRuleArguments valueForKey:weekOfMonthArgument];
            if (weekOfMonth != nil) {
                if (namedFrequency == EKRecurrenceFrequencyYearly || [weekOfMonth intValue] == -1) {
                    EKRecurrenceDayOfWeek *dayOfTheWeek = [EKRecurrenceDayOfWeek dayOfWeek:[dayOfWeekIndex integerValue] + 1 weekNumber: [weekOfMonth intValue]];
                    [daysOfWeek addObject: dayOfTheWeek];
                }
            } else {
                [daysOfWeek addObject:[EKRecurrenceDayOfWeek dayOfWeek:[dayOfWeekIndex integerValue] + 1]];
            }
        }
    }
    NSMutableArray *dayOfMonthArray;
    NSNumber *dayOfMonth = [recurrenceRuleArguments valueForKey:monthOfYearArgument];
    if (dayOfMonth != nil) {
        dayOfMonthArray = [NSMutableArray new];
        [dayOfMonthArray addObject: dayOfMonth];
    }
    NSMutableArray *monthOfYearArray;
    NSNumber *monthOfYear = [recurrenceRuleArguments valueForKey:monthOfYearArgument];
    if (monthOfYear != nil) {
        monthOfYearArray = [NSMutableArray new];
        [monthOfYearArray addObject: monthOfYear];
    }
    NSMutableArray *weekOfMonthArray;
    if (namedFrequency == EKRecurrenceFrequencyMonthly) {
        NSNumber *weekOfMonth = [recurrenceRuleArguments valueForKey:weekOfMonthArgument];
        if (weekOfMonth != nil) {
            weekOfMonthArray = [NSMutableArray init];
            [weekOfMonthArray addObject:weekOfMonth];
        }
    }
    NSMutableArray *ekRecurrenceRules = [NSMutableArray new];
    EKRecurrenceRule *ekRecurrenceRule = [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:
     namedFrequency
     interval:recurrenceInterval
     daysOfTheWeek:daysOfWeek
     daysOfTheMonth:dayOfMonthArray
     monthsOfTheYear:monthOfYearArray
     weeksOfTheYear:nil
     daysOfTheYear:nil
     setPositions:weekOfMonthArray
     end:recurrenceEnd
    ];
    [ekRecurrenceRules addObject: ekRecurrenceRule];
    return ekRecurrenceRules;
}

-(void)setAttendees: (NSDictionary *)arguments event:(EKEvent *)ekEvent{
    NSDictionary *attendeesArguments = [arguments valueForKey:attendeesArgument];
    if (attendeesArguments == nil) {
        return;
    }
    
    NSMutableArray *attendees = [NSMutableArray new];
    for (NSString *attendeeArguments in attendeesArguments) {
        NSString *name = [attendeesArguments valueForKey:nameArgument];
        NSString *emailAddress = [attendeeArguments valueForKey:emailAddressArgument];
        NSNumber *role = [attendeeArguments valueForKey:roleArgument];
        if ([ekEvent attendees] != nil) {
            NSArray *participants = [ekEvent attendees];
            EKParticipant *existingAttendee;
            for(EKParticipant* participant in participants) {
                if ([[participant URL] resourceSpecifier] == emailAddress) {
                    existingAttendee = participant;
                    break;
                }
            }
            if (existingAttendee != nil && [[[ekEvent organizer] URL] resourceSpecifier] != [[existingAttendee URL] resourceSpecifier]) {
                [attendees addObject: existingAttendee];
                continue;
            }
            EKParticipant *attendee = [self createParticipant:emailAddress name:name role:role];
            if (attendee == nil) {
                continue;
            }
            if (existingAttendee != nil && [[[ekEvent organizer] URL] resourceSpecifier] != [[existingAttendee URL] resourceSpecifier]) {
                [attendees addObject: existingAttendee];
                continue;
            }
        }
        EKParticipant *attendee = [self createParticipant:emailAddress name:name role:role];
        if (attendee == nil) {
            continue;
        }
        [attendees addObject: attendee];
    }
    [ekEvent setValue:attendees forKey:@"attendees"];
}

-(NSArray*)createReminders: (NSDictionary *)arguments {
    NSDictionary *remindersArguments = [arguments valueForKey:remindersArgument];
    if (remindersArguments == nil) {
        return nil;
    }
    NSMutableArray *reminders = [NSMutableArray new];
    for (NSString *reminderArguments in remindersArguments) {
        NSNumber *arg = [reminderArguments valueForKey:minutesArgument];
        NSNumber *reminder = [NSNumber numberWithDouble:fabs([arg doubleValue])];
        NSNumber *relativeOffset = [[NSNumber alloc] initWithDouble: (0 - 60 * [reminder doubleValue])];
        [reminders addObject:[EKAlarm alarmWithRelativeOffset:[relativeOffset doubleValue]]];
    }
    return reminders;
}

-(void)createOrUpdateEvent: (FlutterMethodCall *)call result:(FlutterResult)result{
    [self checkPermissionsThenExecute:nil permissionsGrantedAction:^{
        NSDictionary *arguments = [call arguments];
        NSString *calendarId = [arguments valueForKey:calendarIdArgument];
        NSString *eventId = [arguments valueForKey:eventIdArgument];
        BOOL isAllDay = [[arguments valueForKey:eventAllDayArgument] boolValue];
        NSNumber *startDateMillisecondsSinceEpoch = [arguments valueForKey: eventStartDateArgument];
        NSNumber *endDateDateMillisecondsSinceEpoch = [arguments valueForKey: eventEndDateArgument];
        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970: [startDateMillisecondsSinceEpoch doubleValue] / 1000.0 ];
        NSDate *endDate = [NSDate dateWithTimeIntervalSince1970: [endDateDateMillisecondsSinceEpoch doubleValue] / 1000.0 ];
        NSString *title = [arguments valueForKey: eventTitleArgument];
        NSString *description = [arguments valueForKey: eventDescriptionArgument];
        NSString *location = [arguments valueForKey: eventLocationArgument];
        EKCalendar *ekCalendar = [eventStore calendarWithIdentifier: calendarId];
        NSString *url = [arguments valueForKey:eventURLArgument];
        
        if (ekCalendar == nil) {
            [self finishWithCalendarNotFoundError:calendarId result: result];
            return;
        }
        if (![ekCalendar allowsContentModifications]) {
            [self finishWithCalendarReadOnlyError:calendarId result:result];
            return;
        }
        EKEvent *ekEvent;
        if ([eventId isEqual:[NSNull null]]) {
            ekEvent = [EKEvent eventWithEventStore:eventStore];
        } else {
            ekEvent = [eventStore eventWithIdentifier:eventId];
            if (ekEvent == nil) {
                [self finishWithEventNotFoundError: eventId result: result];
                return;
            }
        }
        [ekEvent setTitle:title];
        [ekEvent setNotes:description];
        [ekEvent setAllDay:isAllDay];
        [ekEvent setStartDate:startDate];
        if (isAllDay) {
            [ekEvent setEndDate:startDate];
        } else {
            [ekEvent setEndDate:endDate];
        }
        [ekEvent setCalendar:ekCalendar];
        [ekEvent setLocation:location];
        if (![url isEqual:[NSNull null]]) {
            ekEvent.URL = [NSURL URLWithString: url];
        } else {
            ekEvent.URL = [NSURL URLWithString: @""];
        }
        [ekEvent setRecurrenceRules: [self createEKRecurrenceRules: arguments]];
        [self setAttendees:arguments event:ekEvent];
        [ekEvent setAlarms: [self createReminders: arguments]];
        [ekEvent setAvailability: [self setAvailability:arguments]];
        NSError *error = nil;
        [eventStore saveEvent:ekEvent span:EKSpanFutureEvents error:&error];
        if (error == nil) {
            result([ekEvent eventIdentifier]);
        } else {
            [eventStore reset];
            result([FlutterError errorWithCode:genericError message: [error localizedDescription] details:nil ]);
        }

    } result: result];
}

-(EKParticipant *)createParticipant:(NSString *)emailAddress name:(NSString *)name role:(NSNumber *)role {
    Class ekAttendeeClass = NSClassFromString(@"EKAttendee");
    id participant = [ekAttendeeClass new];
    [participant setValue:emailAddress forKey:@"emailAddress"];
    [participant setValue:name forKey:@"displayName"];
    [participant setValue:role forKey:@"participantRole"];
    return participant;
}

-(void)deleteEvent:(FlutterMethodCall *)call result:(FlutterResult)result {
    [self checkPermissionsThenExecute:nil permissionsGrantedAction:^{
        NSDictionary<NSString*, id> *arguments = call.arguments;
        NSString *calendarId = [arguments valueForKey:calendarIdArgument];
        NSString *eventId = [arguments valueForKey:eventIdArgument];
        NSNumber *startDateNumber = [arguments valueForKey:eventStartDateArgument];
        NSNumber *endDateNumber = [arguments valueForKey:eventEndDateArgument];
        BOOL followingInstances = [arguments valueForKey:followingInstancesArgument];
        EKCalendar *ekCalendar = [eventStore calendarWithIdentifier: calendarId];
        NSError *error = nil;
        if (ekCalendar == nil) {
            [self finishWithCalendarNotFoundError:calendarId result: result];
            return;
        }
        if (![ekCalendar allowsContentModifications]) {
            [self finishWithCalendarReadOnlyError:calendarId result: result];
            return;
        }
        if (startDateNumber == nil && endDateNumber == nil && followingInstances == NO) {
            EKEvent *ekEvent = [eventStore eventWithIdentifier: eventId];
            if (ekEvent == nil) {
                [self finishWithEventNotFoundError:eventId result: result];
                return;
            }
            [eventStore removeEvent:ekEvent span:EKSpanFutureEvents error:&error];
        }else {
            NSDate *startDate = [NSDate dateWithTimeIntervalSince1970: [startDateNumber doubleValue] / 1000.0];
            NSDate *endDate = [NSDate dateWithTimeIntervalSince1970: [endDateNumber doubleValue] / 1000.0];
            
            NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:nil];
            NSArray *foundEkEvents = [eventStore eventsMatchingPredicate:predicate];
            if (foundEkEvents == nil || [foundEkEvents count] == 0) {
                [self finishWithEventNotFoundError:eventId result:result];
                return;
            }
            NSMutableArray *ekEvents = [NSMutableArray new];
            for (EKEvent *event in foundEkEvents) {
                if (event.eventIdentifier == eventId) {
                    [ekEvents addObject:event];
                    break;
                }
            }
            if (!followingInstances) {
                [eventStore removeEvent:ekEvents.firstObject span:EKSpanThisEvent commit: YES error:&error];
            } else {
                [eventStore removeEvent:ekEvents.firstObject span:EKSpanFutureEvents commit: YES error:&error];
            }
        }
        if (error == nil) {
            result([NSNumber numberWithBool:YES]);
        } else {
            [eventStore reset];
            result([FlutterError errorWithCode:genericError message: [error localizedDescription] details:nil ]);
        }
    } result:result];
}

-(void)finishWithUnauthorizedError:(id)args result:(FlutterResult)result{
    result([FlutterError errorWithCode:unauthorizedErrorCode message:unauthorizedErrorMessage details:nil]);
}

-(void)finishWithCalendarNotFoundError:(NSString *)calendarId result:(FlutterResult)result{
    NSString *errorMessage = [calendarNotFoundErrorMessageFormat stringByAppendingFormat: calendarId];
    result([FlutterError errorWithCode:notFoundErrorCode message:errorMessage details:nil]);
}

-(void)finishWithCalendarReadOnlyError:(NSString *)calendarId result:(FlutterResult)result{
    NSString *errorMessage = [calendarReadOnlyErrorMessageFormat stringByAppendingFormat: calendarId];
    result([FlutterError errorWithCode:notAllowed message:errorMessage details:nil]);
}

-(void)finishWithEventNotFoundError: (NSString *)eventId result:(FlutterResult)result {
    NSString *errorMessage = [eventNotFoundErrorMessageFormat stringByAppendingFormat: eventId];
    result([FlutterError errorWithCode:notFoundErrorCode message:errorMessage details:nil]);
}

-(void)encodeJsonAndFinish: (Department *)codable result:(FlutterResult)result {
    NSMutableArray *resultArr = [NSMutableArray new];
    if ([codable.calendars count] > 0) {
        for(Calendar *calendar in codable.calendars) {
            [resultArr addObject:[calendar toJSONString]];
        }
    } else if ([codable.events count] > 0) {
        for(Event *event in codable.events) {
            NSMutableArray *reminders = [NSMutableArray new];
            for (Reminder *remeinder in event.reminders) {
                [reminders addObject:[remeinder toDictionary]];
            }
            NSMutableArray *attendees = [NSMutableArray new];
            for (Attendee *attendee in event.attendees) {
                [attendees addObject:[attendee toDictionary]];
            }
            event.attendees = attendees;
            event.reminders = reminders;
            [resultArr addObject:[event toJSONString]];
        }
    }
    
    NSString * arrayToString = [[resultArr valueForKey:@"description"] componentsJoinedByString:@","];
    NSString *resultStr = [[NSString alloc] initWithFormat:@"[%@]", arrayToString];
    result(resultStr);
}

-(void)checkPermissionsThenExecute:(id)args permissionsGrantedAction:(void (^)(void))permissionsGrantedAction result:(FlutterResult)result {
    if ([self hasEventPermissions]) {
        permissionsGrantedAction();
        return;
    }
    [self finishWithUnauthorizedError:nil result:result];
}

-(void) selector: (FlutterResult *) result {
    
}

-(void)requestPermissions: completion:(void (^)(BOOL success))complet {
    if ([self hasEventPermissions]) {
        complet(YES);
    } else {
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
            complet(granted);
        }];
    }
}

-(BOOL)hasEventPermissions {
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType: EKEntityTypeEvent];
    return status == EKAuthorizationStatusAuthorized;
}

-(void)requestPermissions:(id)args result:(FlutterResult)result {
    if ([self hasEventPermissions])
        result([NSNumber numberWithBool:YES]);
    [eventStore requestAccessToEntityType: EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
        result([NSNumber numberWithBool:granted]);
    }];
}
@end
