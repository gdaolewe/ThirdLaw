//
//  GenericSavedPage.h
//  Lampshade
//
//  Created by George Daole-Wellman on 8/21/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GenericSavedPage <NSObject>
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * html;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSDate * date;
@end
