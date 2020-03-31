#import <Foundation/Foundation.h>
#import "RecurrenceRule.h"
#import "Attendee.h"
#import "JSONModel/JSONModel.h"

@interface Event : JSONModel

@property NSString *eventId;
@property NSString *calendarId;
@property NSString *title;
@property NSString *description;
@property NSInteger start;
@property NSInteger end;
@property BOOL allDay;
@property NSArray *attendees;
@property NSString *location;
@property RecurrenceRule *recurrenceRule;
@property Attendee *organizer;
@property NSMutableArray *reminders;

@end
