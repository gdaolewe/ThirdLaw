//
//  SearchViewController.h
//  Lampshade
//
//  Created by George Daole-Wellman on 1/15/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SearchViewDelegate <NSObject>
-(void)searchViewController:(id)controller didSelectSearchResult:(NSString*)result;
@end

@interface SearchViewController : UIViewController
@property (nonatomic, weak)NSObject<SearchViewDelegate> *delegate;
@end
