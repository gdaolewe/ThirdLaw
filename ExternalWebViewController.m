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
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    self.webView.hidden = NO;
	_defaults = [NSUserDefaults standardUserDefaults];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self setupRotationLockButton];
	[super viewDidAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(showRotationLockButton)
												 name:UIDeviceOrientationDidChangeNotification object:nil];
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
    self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
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
        [self.rotationLockButton setImage:[UIImage imageNamed:@"locked.png"] forState:UIControlStateNormal];
    } else {
        [self.rotationLockButton setImage:[UIImage imageNamed:@"unlocked.png"] forState:UIControlStateNormal];
    }
}

NSTimer *_timer;

-(void) showRotationLockButton {
	self.rotationLockButton.hidden = NO;
	if (_timer != nil)
		[_timer invalidate];
	_timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hideRotationLockButtonAfterTimer:) userInfo:nil repeats:NO];
}
-(void) hideRotationLockButtonAfterTimer:(NSTimer*)timer {
	[self.rotationLockButton setHidden:YES];
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
