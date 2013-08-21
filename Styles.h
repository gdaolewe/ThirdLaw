//
//  Styles.h
//  Lampshade
//
//  Created by George Daole-Wellman on 8/20/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Styles : NSObject
+(UIColor*) darkBlueColor;

+(NSString*) defaultFontFamily;
+(NSString*) defaultFontFamilyBold;

+(void)setFontFamily:(NSString*)fontFamily forView:(UIView*)view andSubViews:(BOOL)isSubViews;
@end
