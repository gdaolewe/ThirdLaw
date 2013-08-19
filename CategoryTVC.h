//
//  CategoryTVC.h
//  TVTropes
//
//  Created by George Daole-Wellman on 11/10/12.
//  Copyright (c) 2012 George Daole-Wellman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IndexData.h"

@interface CategoryTVC : UITableViewController <UITableViewDelegate>


@property IndexData *categoryData;
@property BOOL loaded;
@property NSString *labelText;

@end
