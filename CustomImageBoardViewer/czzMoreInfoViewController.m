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
#import "UINavigationController+Util.h"
#import "czzURLHandler.h"

@interface czzMoreInfoViewController ()<WKNavigationDelegate, UIGestureRecognizerDelegate>
@property (strong, nonatomic) NSString *baseURL;
@property (copy, nonatomic) NSData *coverData;
@property (strong, nonatomic) czzImageViewerUtil *imageViewerUtil;
@property (weak, nonatomic) NSLayoutConstraint *headerTextWebViewHeight;
@property (weak, nonatomic) NSLayoutConstraint *coverImageWebViewHeight;
@end

@implementation czzMoreInfoViewController
@synthesize baseURL;
@synthesize bannerView_;
@synthesize moreInfoNavItem;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.extendedLayoutIncludesOpaqueBars = YES;
    }
    return self;
}

- (void)loadView {
    UIView *rootView = [[UIView alloc] init];
    rootView.backgroundColor = [UIColor whiteColor];
    self.view = rootView;

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [rootView addSubview:scrollView];
    self.containerScrollView = scrollView;

    UIImageView *coverWebView = [[UIImageView alloc] init];
    coverWebView.translatesAutoresizingMaskIntoConstraints = NO;
    coverWebView.contentMode = UIViewContentModeScaleAspectFit;
    coverWebView.backgroundColor = [UIColor whiteColor];
    coverWebView.userInteractionEnabled = YES;
    UITapGestureRecognizer *coverTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnCoverImageViewAction:)];
    coverTap.delegate = self;
    [coverWebView addGestureRecognizer:coverTap];
    [scrollView addSubview:coverWebView];
    self.coverImageView = coverWebView;

    WKWebView *headerWebView = [[WKWebView alloc] initWithFrame:CGRectZero];
    headerWebView.translatesAutoresizingMaskIntoConstraints = NO;
    headerWebView.backgroundColor = [UIColor colorWithRed:0.290 green:0.315 blue:0.330 alpha:1];
    headerWebView.opaque = NO;
    headerWebView.navigationDelegate = self;
    headerWebView.scrollView.bounces = NO;
    [scrollView addSubview:headerWebView];
    self.headerTextWebView = headerWebView;

    NSLayoutConstraint *coverHeight = [coverWebView.heightAnchor constraintEqualToConstant:120];
    NSLayoutConstraint *headerHeight = [headerWebView.heightAnchor constraintEqualToConstant:120];
    self.coverImageWebViewHeight = coverHeight;
    self.headerTextWebViewHeight = headerHeight;
    NSLayoutConstraint *scrollBottom = [scrollView.bottomAnchor constraintEqualToAnchor:rootView.safeAreaLayoutGuide.bottomAnchor];
    scrollBottom.priority = UILayoutPriorityDefaultLow;

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],
        [scrollView.topAnchor constraintEqualToAnchor:rootView.layoutMarginsGuide.topAnchor],
        scrollBottom,

        [coverWebView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [coverWebView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [coverWebView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [coverWebView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],
        coverHeight,

        [headerWebView.topAnchor constraintEqualToAnchor:coverWebView.bottomAnchor],
        [headerWebView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [headerWebView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [headerWebView.widthAnchor constraintEqualToAnchor:rootView.widthAnchor],
        [headerWebView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        headerHeight
    ]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"更多信息";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"delete.png"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissAction:)];
    self.moreInfoNavItem = self.navigationItem;
	// Do any additional setup after loading the view.
    baseURL = [settingCentre get_forum_info_url];
    //admob module
    bannerView_ = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.view.backgroundColor = [settingCentre viewBackgroundColour];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // Load image.
    [self renderContent];
}

-(void)renderContent {
    [self.navigationController applyAppearance];
    // Disable bounce.
    self.headerTextWebView.scrollView.bounces = NO;
    // Position of the banner view.
    // Constraints, all to the super view, except the top.
//    [bannerView_ loadRequest:[GADRequest request]];
    [self.view addSubview:bannerView_];
    bannerView_.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [bannerView_.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [bannerView_.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [bannerView_.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.containerScrollView.bottomAnchor constraintEqualToAnchor:bannerView_.topAnchor constant:-16]
    ]];
    @try {
        // Initially hide the cover image web view.
        self.coverImageWebViewHeight.constant = 0;
        if (self.forum) {
            //load forum info
            self.title = [NSString stringWithFormat:@"介绍：%@", self.forum.name];
            NSString *headerText = [self.forum.header stringByReplacingOccurrencesOfString:@"@Time" withString:[NSString stringWithFormat:@"%ld", (long)self.forum.cooldown]];
            [self.headerTextWebView loadHTMLString:[self htmlFittedForDeviceWidth:headerText] baseURL:nil];
            // Set the height to be the min of the width and height of self.view.frame.
            self.headerTextWebViewHeight.constant = MIN(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
        } else {
            self.title = @"A岛-AC匿名版";
            // No selected forum, load default value.
            NSString *rulesHtml = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"rules"
                                                                                                           ofType:@"html"]
                                                                  encoding:NSUTF8StringEncoding
                                                                     error:nil];
            [self.headerTextWebView loadHTMLString:[self htmlFittedForDeviceWidth:rulesHtml]
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
                            // Placeholder height, set the height of the image view to be either the width or the height.
                            self.coverImageWebViewHeight.constant = MIN(CGRectGetHeight(self.view.frame), CGRectGetWidth(self.view.frame));
                        }
                        self.coverImageView.image = coverImage;
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

#pragma mark - WKNavigationDelegate, open links in safari

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        [czzURLHandler handleURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

// WKWebView has no scalesPageToFit equivalent. Injecting a viewport makes the
// fragment render at the device width instead of the default 980pt layout.
- (NSString *)htmlFittedForDeviceWidth:(NSString *)html {
    if (!html.length) {
        return @"";
    }
    NSString *viewport = @"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">";
    return [viewport stringByAppendingString:html];
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
    return [[self alloc] init];
}

@end
