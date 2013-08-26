//
//  ExternalWebViewController.m
//  Lampshade
//
//  Created by George Daole-Wellman on 1/28/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "ExternalWebViewController.h"
#import "UserDefaultsHelper.h"

@interface ExternalWebViewController () <UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIButton *rotationLockButton;

@end

@implementation ExternalWebViewController

@synthesize url = _url;
@synthesize webView = _webView;

NSUserDefaults *_defaults;

- (void)viewDidLoad
{
    [super viewDidLoad];
    //self.webView = [[UIWebView alloc] init];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    self.webView.hidden = NO;
	_defaults = [NSUserDefaults standardUserDefaults];
	[self setupRotationLockButton];
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [self setWebView:nil];
    [self setWebView:nil];
	[self setRotationLockButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    //self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (IBAction)toggleRotationLock:(UIButton *)sender {
	BOOL rotationLocked = [_defaults boolForKey:USER_PREF_ROTATION_LOCKED];
    if (rotationLocked) {   //unlock rotation
        [_defaults setBool:NO forKey:USER_PREF_ROTATION_LOCKED];
        [self.class attemptRotationToDeviceOrientation];
    } else {    //lock rotation to current orientation
        [_defaults setBool:YES forKey:USER_PREF_ROTATION_LOCKED];
        [_defaults setInteger:self.interfaceOrientation forKey:USER_PREF_ROTATION_ORIENTATION];
    }
    [_defaults synchronize];
    [self setupRotationLockButton];
}


-(void)setupRotationLockButton {
    BOOL rotationLocked = [_defaults boolForKey:USER_PREF_ROTATION_LOCKED];
    if (rotationLocked) {
        [self.rotationLockButton setTitle:@"Unlock" forState:UIControlStateNormal];
    } else {
        [self.rotationLockButton setTitle:@"Lock" forState:UIControlStateNormal];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    BOOL rotationLocked = [_defaults boolForKey:USER_PREF_ROTATION_LOCKED];
    NSInteger rotationOrientation = [_defaults integerForKey:USER_PREF_ROTATION_ORIENTATION];
    if (rotationLocked) {
        if (interfaceOrientation == rotationOrientation)
            return YES;
        else if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight)
                 && (rotationOrientation == UIInterfaceOrientationLandscapeLeft || rotationOrientation == UIInterfaceOrientationLandscapeRight))
            return YES;
        else
            return NO;
        return (UIInterfaceOrientationPortrait == interfaceOrientation);
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
}

@end
