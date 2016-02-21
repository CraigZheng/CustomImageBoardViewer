//
//  czzMoreInfoViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 29/11/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#define COVER_URL @"http://cover.acfunwiki.org/cover.php"

#import "czzMoreInfoViewController.h"
#import "SMXMLDocument.h"
#import "czzAppDelegate.h"
#import "czzSettingsCentre.h"
#import "czzBannerNotificationUtil.h"
#import "czzForum.h"
#import "czzImageViewerUtil.h"
#import <PureLayout/PureLayout.h>

@interface czzMoreInfoViewController ()<UIWebViewDelegate, UIGestureRecognizerDelegate>
@property (strong, nonatomic) NSString *baseURL;
@property (copy, nonatomic) NSData *coverData;
@property (strong, nonatomic) czzImageViewerUtil *imageViewerUtil;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerTextWebViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *coverImageWebViewHeight;
@end

@implementation czzMoreInfoViewController
@synthesize baseURL;
@synthesize bannerView_;
@synthesize moreInfoNavItem;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    baseURL = [settingCentre get_forum_info_url];
    //admob module
    bannerView_ = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerLandscape];
    bannerView_.adUnitID = @"ca-app-pub-2081665256237089/4247713655";
    bannerView_.rootViewController = self;
    
    //colours
    self.navigationController.navigationBar.barTintColor = [settingCentre barTintColour];
    self.navigationController.navigationBar.tintColor = [settingCentre tintColour];
     [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : self.navigationController.navigationBar.tintColor}];
    self.view.backgroundColor = [settingCentre viewBackgroundColour];
    // Load image.
    [self renderContent];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];    
    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

-(void)renderContent {
    // Position of the banner view.
    // Constraints, all to the super view, except the top.
    [bannerView_ loadRequest:[GADRequest request]];
    [self.view addSubview:bannerView_];
//    [bannerView_ autoSetDimensionsToSize:kGADAdSizeSmartBannerLandscape.size];
    [bannerView_ autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero
                                          excludingEdge:ALEdgeTop];
    // Relative position of the banner view and the web view.
    [self.containerScrollView autoPinEdge:ALEdgeBottom
                                 toEdge:ALEdgeTop
                                 ofView:bannerView_
                             withOffset:16];
    @try {
        // Initially hide the cover image web view.
        self.coverImageWebViewHeight.constant = 0;
        if (self.forum) {
            //load forum info
            self.title = [NSString stringWithFormat:@"介绍：%@", self.forum.name];
            NSString *headerText = [self.forum.header stringByReplacingOccurrencesOfString:@"@Time" withString:[NSString stringWithFormat:@"%ld", (long)self.forum.cooldown]];
            [self.headerTextWebView loadHTMLString:headerText baseURL:Nil];
            // Set the height to be the min of the width and height of self.view.frame.
            self.headerTextWebViewHeight.constant = MIN(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
        } else {
            self.title = @"A岛-AC匿名版";
            self.coverImageWebView.scalesPageToFit = YES;
            // No selected forum, load default value.
            NSString *rulesHtml = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"rules"
                                                                                                           ofType:@"html"]
                                                                  encoding:NSUTF8StringEncoding
                                                                     error:nil];
            [self.headerTextWebView loadHTMLString:rulesHtml
                                           baseURL:nil];
            // Set the height of the text web view to be the max of width or height.
            self.headerTextWebViewHeight.constant = MAX(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSError *error;
                self.coverData = [NSData dataWithContentsOfURL:[NSURL URLWithString:COVER_URL] options:NSDataReadingUncached error:&error];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!error && self.coverData) {
                        // Set the height of the image web view to be either the width or the height.
                        self.coverImageWebViewHeight.constant = MIN(CGRectGetHeight(self.view.frame), CGRectGetWidth(self.view.frame));
                        [self.coverImageWebView loadData:self.coverData MIMEType:@"image/jpeg" textEncodingName:@"utf-8" baseURL:[NSURL new]];
                    } else {
                         self.coverData = nil;
                    }
                });
            });
        }
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
    }
    moreInfoNavItem.title = self.title;
}

#pragma mark - UI actions
- (IBAction)tapOnCoverImageViewAction:(id)sender {
    if (self.coverData) {
        UIImage *coverImage = [UIImage imageWithData:self.coverData];
        self.imageViewerUtil = [czzImageViewerUtil new];
        self.imageViewerUtil.destinationViewController = self.navigationController ? self.navigationController : self;
        [self.imageViewerUtil showPhotoWithImage:coverImage];
    }
}

- (IBAction)dismissAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIWebView delegate, open links in safari

- (BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

#pragma mark - UIGestureRecognizerDelegate

// This is required in order to get the gesture reconizer working on a web view.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (IBAction)homePageAction:(id)sender {
    NSString *homePageURL = @"http://www.weibo.com/u/3868827431"; // Weibo home page URL
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:homePageURL]];

}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"more_info_view_controller"];
}

@end
