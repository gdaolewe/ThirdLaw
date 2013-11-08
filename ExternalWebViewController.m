//
//  ExternalWebViewController.m
//  Lampshade
//
//  Created by George Daole-Wellman on 1/28/13.
//  Copyright (c) 2013 George Daole-Wellman. All rights reserved.
//

#import "ExternalWebViewController.h"
#import "UserDefaultsHelper.h"

@interface ExternalWebViewController () <UIWebViewDelegate, UIActionSheetDelegate>
@property (strong, nonatomic) IBOutlet UIButton *rotationLockButton;
@property (strong, nonatomic) IBOutlet UIButton *fullscreenOffButton;

//toolbar items
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *actionsButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *fullscreenButton;

@end

@implementation ExternalWebViewController

@synthesize url = _url;
@synthesize webView = _webView;
@synthesize rotationLockButton = _rotationLockButton;
@synthesize fullscreenOffButton = _fullScreenOffButton;

NSUserDefaults *_defaults;

-(NSURL *)url {
	return _url;
}
-(void)setUrl:(NSURL *)url {
	_url = url;
	[_defaults setObject:self.url.absoluteString forKey:USER_PREF_EXTERNAL_URL];
	[_defaults synchronize];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	if (!self.url) {
		NSString *savedURLString = [_defaults objectForKey:USER_PREF_EXTERNAL_URL];
		if (savedURLString.length > 0)
			self.url = [NSURL URLWithString:savedURLString];
		else
			[self dismissViewControllerAnimated:NO completion:nil];
	}
	if (self.navigationController.navigationBarHidden) {
		
	}
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    self.webView.hidden = NO;
	_defaults = [NSUserDefaults standardUserDefaults];
	[self setFullscreen:[_defaults boolForKey:USER_PREF_FULLSCREEN]];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self setupRotationLockButton];
	[_defaults setInteger:USerPrefStartViewExternal forKey:USER_PREF_START_VIEW];
	[_defaults synchronize];
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
	[self setFullscreenOffButton:nil];
	[self setBackButton:nil];
	[self setForwardButton:nil];
	[self setActionsButton:nil];
	[self setFullscreenButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}
- (IBAction)back:(UIBarButtonItem *)sender {
	if (self.webView.canGoBack)
		[self.webView goBack];
}
- (IBAction)forward:(UIBarButtonItem *)sender {
	if (self.webView.canGoForward)
		[self.webView goForward];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0)
		if (![[UIApplication sharedApplication] openURL:self.url])
			NSLog(@"%@%@",@"Failed to open url:",self.url);
}


- (IBAction)actions:(UIBarButtonItem *)sender {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open in Safari", nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

BOOL _isFullScreen = NO;

- (IBAction)toggleFullscreen:(id)sender {
	[self setFullscreen:!_isFullScreen];
}

-(void) setFullscreen:(BOOL)fullscreen {
	_isFullScreen = fullscreen;
	[_defaults setBool:fullscreen forKey:USER_PREF_FULLSCREEN];
	if (fullscreen) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        [self.navigationController setToolbarHidden:YES animated:YES];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        self.fullscreenOffButton.hidden = NO;
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        [self.navigationController setToolbarHidden:NO animated:YES];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        self.fullscreenOffButton.hidden = YES;
    }

}

#pragma mark - UIWebViewDelegate
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType != UIWebViewNavigationTypeOther) {
		self.url = request.mainDocumentURL;
	}
	return YES;
}
-(void)webViewDidStartLoad:(UIWebView *)webView {
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:webView action:@selector(stopLoading)];
	if (webView.canGoBack)
		self.backButton.enabled = YES;
	else
		self.backButton.enabled = NO;
	if (webView.canGoForward)
		self.forwardButton.enabled = YES;
	else
		self.forwardButton.enabled = NO;
	UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	self.navigationController.toolbarItems = [NSArray arrayWithObjects:self.backButton, flexSpace, self.forwardButton, flexSpace, self.actionsButton, flexSpace, self.fullscreenButton, nil];
}
-(void)webViewDidFinishLoad:(UIWebView *)webView {
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:webView action:@selector(reload)];

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

NSTimer *_webviewLockHidetimer;

-(void) showRotationLockButton {
	self.rotationLockButton.hidden = NO;
	if (_webviewLockHidetimer != nil)
		[_webviewLockHidetimer invalidate];
	_webviewLockHidetimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hideRotationLockButtonAfterTimer:) userInfo:nil repeats:NO];
}
-(void) hideRotationLockButtonAfterTimer:(NSTimer*)theTimer {
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
