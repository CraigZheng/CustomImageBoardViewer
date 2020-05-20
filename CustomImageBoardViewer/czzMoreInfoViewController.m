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
#import "UINavigationController+Util.h"

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
#ifdef DEBUG
    bannerView_.adUnitID = @"ca-app-pub-3940256099942544/6300978111";
#else
    bannerView_.adUnitID = @"ca-app-pub-2081665256237089~1718587650";
#endif
    bannerView_.rootViewController = self;
    
    self.view.backgroundColor = [settingCentre viewBackgroundColour];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // Load image.
    [self renderContent];

    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

-(void)renderContent {
    [self.navigationController applyAppearance];
    // Disable bounce.
    self.coverImageWebView.scrollView.bounces =
    self.headerTextWebView.scrollView.bounces = NO;
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
            // Set the height of the text web view to be the max of width or height and times 1.5 to make it long enough.
            self.headerTextWebViewHeight.constant = MAX(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)) * 1.5;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSError *error;
                self.coverData = [NSData dataWithContentsOfURL:[NSURL URLWithString:COVER_URL] options:NSDataReadingUncached error:&error];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!error && self.coverData) {
                        // Calculate the correct height for the image view.
                        UIImage *coverImage = [[UIImage alloc] initWithData:self.coverData];
                        if (coverImage) {
                            // The width would the the width of self.view, use it and the aspect ratio of the image to get the height.
                            CGFloat width = MIN(CGRectGetHeight(self.view.frame), CGRectGetWidth(self.view.frame));
                            CGFloat height = width * (coverImage.size.height / coverImage.size.width);
                            // The calculated height should not be bigger than the actual image height.
                            if (height > coverImage.size.height) {
                                height = coverImage.size.height;
                            }
                            self.coverImageWebViewHeight.constant = height;
                        } else {
                            // Placeholder height, set the height of the image web view to be either the width or the height.
                            self.coverImageWebViewHeight.constant = MIN(CGRectGetHeight(self.view.frame), CGRectGetWidth(self.view.frame));
                        }
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

#pragma mark - UIStateRestoring

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    if (self.forum) {
        [coder encodeObject:self.forum forKey:@"forum"];
    }
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    czzForum *forum;
    if ([(forum = [coder decodeObjectForKey:@"forum"]) isKindOfClass:[czzForum class]]) {
        self.forum = forum;
    }
}

- (void)applicationFinishedRestoringState {
    [self renderContent];
}

#pragma mark - UIGestureRecognizerDelegate

// This is required in order to get the gesture reconizer working on a web view.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"MoreInfo" bundle:nil] instantiateViewControllerWithIdentifier:@"more_info_view_controller"];
}

@end
