//
//  ExternalWebViewController.m
//  Lampshade
//
//  Created by George Daole-Wellman on 1/28/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "ExternalWebViewController.h"

@interface ExternalWebViewController () <UIWebViewDelegate>

@end

@implementation ExternalWebViewController
@synthesize url = _url;
@synthesize webView = _webView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    //self.webView = [[UIWebView alloc] init];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    self.webView.hidden = NO;
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [self setWebView:nil];
    [self setWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    //self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
