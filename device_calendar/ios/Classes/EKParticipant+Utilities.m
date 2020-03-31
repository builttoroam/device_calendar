#import "EKParticipant+Utilities.h"

@implementation EKParticipant (Utilities)

- (NSString *) emailAddress
{
    return [self valueForKey:@"emailAddress"];
}
@end
