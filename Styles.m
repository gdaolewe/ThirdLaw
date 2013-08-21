//
//  Styles.m
//  Lampshade
//
//  Created by George Daole-Wellman on 8/20/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "Styles.h"

@implementation Styles

+(UIColor*) darkBlueColor {
    return [UIColor colorWithRed:0.03922 green:0.19608 blue:0.4 alpha:1];
}

+(NSString *)defaultFontFamily {
    return @"NoticiaText-Regular";
}

+(NSString *)defaultFontFamilyBold {
    return @"NoticiaText-Bold";
}

+(void)setFontFamily:(NSString*)fontFamily forView:(UIView*)view andSubViews:(BOOL)isSubViews
{
    if ([view isKindOfClass:[UILabel class]])
    {
        UILabel *lbl = (UILabel *)view;
        [lbl setFont:[UIFont fontWithName:fontFamily size:[[lbl font] pointSize]]];
    }
    
    if (isSubViews)
    {
        for (UIView *sview in view.subviews)
        {
            [self setFontFamily:fontFamily forView:sview andSubViews:YES];
        }
    }
}


@end
