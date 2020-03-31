#import "DeviceCalendarExtendedPlugin.h"
#import "DeviceCalendarPlugin.h"

@implementation DeviceCalendarExtendedPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [DeviceCalendarPlugin registerWithRegistrar:registrar];
}
@end
