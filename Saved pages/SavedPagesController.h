//
//  SavedFilesController.h
//  Lampshade
//
//  Created by George Daole-Wellman on 8/13/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SavedPagesDelegate <NSObject>

-(void)savedPageController:(id)controller didSelectSavedPageWithHTML:(NSString*)html andURL:(NSString*)url;
-(void)savedPageController:(id)controller didSelectBookmarkWithURL:(NSString*)url;
@end

@interface SavedPagesController : UIViewController

@property NSObject<SavedPagesDelegate> *delegate;

-(IBAction)deleteRows:(UIBarButtonItem *)sender;
@end
