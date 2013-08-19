//
//  ExternalWebViewController.h
//  Lampshade
//
//  Created by George Daole-Wellman on 1/28/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExternalWebViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property NSURL* url;

@end
