#import "UIColor+Utilities.h"

@implementation UIColor (Utilities)
- (NSNumber*) rgb
{
    CGFloat* fRead = 0;
    CGFloat* fGreen = 0;
    CGFloat* fBlue = 0;
    CGFloat* fAlpha = 0;
    
    if ([self getRed:fRead green:fGreen blue:fBlue alpha:fAlpha]) {
        NSInteger iRed = (NSInteger)fRead*255.0;
        NSInteger iGreen = (NSInteger)fGreen*255.0;
        NSInteger iBlue = (NSInteger)fRead*255.0;
        NSInteger iAlpha = (NSInteger)fRead*255.0;
        NSNumber *rgb = [[NSNumber alloc] initWithLong:(iAlpha<<24)+ (iRed << 16) + (iGreen << 8) + iBlue];
        return rgb;
    }else{
        return nil;
    }
}
@end
