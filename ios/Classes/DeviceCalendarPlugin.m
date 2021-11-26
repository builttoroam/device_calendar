#import "DeviceCalendarPlugin.h"
#import <device_calendar/device_calendar-Swift.h>

@implementation DeviceCalendarPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDeviceCalendarPlugin registerWithRegistrar:registrar];
}
@end
