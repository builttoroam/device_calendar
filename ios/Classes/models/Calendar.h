#import <Foundation/Foundation.h>
#import "JSONModel/JSONModel.h"

@interface Calendar : JSONModel

@property NSString *id;
@property NSString *name;
@property BOOL isReadOnly;
@property BOOL isDefault;
@property NSInteger color;
@property NSString *accountName;
@property NSString *accountType;

@end
