#import "Date+Utilities.h"

@implementation NSDate (Utilities)

- (float) millisecondsSinceEpoch
{
    return [self timeIntervalSince1970] * 1000.0;
}

@end
