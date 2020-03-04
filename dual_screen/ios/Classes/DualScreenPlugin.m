#import "DualScreenPlugin.h"
#if __has_include(<dual_screen/dual_screen-Swift.h>)
#import <dual_screen/dual_screen-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "dual_screen-Swift.h"
#endif

@implementation DualScreenPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDualScreenPlugin registerWithRegistrar:registrar];
}
@end
