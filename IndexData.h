//
//  CategoryData.h
//  TVTropes
//
//  Created by George Daole-Wellman on 11/10/12.
//  Copyright (c) 2012 George Daole-Wellman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IndexData : NSObject

@property int indexDepth;
@property int categoryIndex;

+(IndexData *)sharedIndexData;

-(int) categoryCount;
-(int) examplesCountForCategoryIndex:(int)categoryIndex;

-(void) loadHTML;

-(NSString *)categoryNameAtIndex:(int)index;

-(NSString *)exampleNameForCategoryIndex:(int)category atIndex:(int) index;

-(NSString *)urlForCategoryIndex:(int)category atIndex:(int)index;

@end
