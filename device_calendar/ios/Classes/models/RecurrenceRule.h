#import <Foundation/Foundation.h>
#import "JSONModel/JSONModel.h"

@interface RecurrenceRule : JSONModel

@property NSInteger recurrenceFrequency;
@property NSNumber *totalOccurrences;
@property NSInteger interval;
@property NSNumber *endDate;
@property NSArray *daysOfWeek;
@property NSInteger daysOfMonth;
@property NSInteger monthsOfYear;
@property NSInteger weeksOfYear;
@property NSInteger weekOfMonth;

@end
