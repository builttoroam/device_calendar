#import <Foundation/Foundation.h>
#import "JSONModel/JSONModel.h"

@interface Department : JSONModel
@property NSMutableArray *calendars;
@property NSMutableArray *events;
@end
