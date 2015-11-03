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
#import "Toast+UIView.h"
#import "czzForum.h"

@interface czzMoreInfoViewController ()<UIWebViewDelegate>
@property (strong, nonatomic) NSString *baseURL;
@end

@implementation czzMoreInfoViewController
@synthesize headerTextWebView;
@synthesize baseURL;
@synthesize bannerView_;
@synthesize moreInfoNavItem;
@synthesize moreInfoNaviBar;
@synthesize barBackgroundView;

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
    moreInfoNaviBar.barTintColor = [settingCentre barTintColour];
    moreInfoNaviBar.tintColor = [settingCentre tintColour];
    [moreInfoNaviBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : moreInfoNaviBar.tintColor}];

    barBackgroundView.backgroundColor = [settingCentre barTintColour];
    self.view.backgroundColor = [settingCentre viewBackgroundColour];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self renderContent];
    
    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

-(void)renderContent {
    //position of the ad
    [bannerView_ setFrame:CGRectMake(0, self.view.bounds.size.height - bannerView_.bounds.size.height, CGRectGetWidth(bannerView_.frame),
                                     CGRectGetHeight(bannerView_.frame))];
    [bannerView_ loadRequest:[GADRequest request]];
    [self.view addSubview:bannerView_];
    
    if (headerTextWebView.loading){
        [headerTextWebView stopLoading];
    }
    
    // Scaled page would be too small for text.
    headerTextWebView.scalesPageToFit = NO;
    @try {
        if (self.forum) {
            //load forum info
            self.title = [NSString stringWithFormat:@"介绍：%@", self.forum.name];
            NSString *headerText = [self.forum.header stringByReplacingOccurrencesOfString:@"@Time" withString:[NSString stringWithFormat:@"%ld", (long)self.forum.cooldown]];
            [headerTextWebView loadHTMLString:headerText baseURL:Nil];
            
        } else {
            self.title = @"A岛-AC匿名版";
            // No selected forum, load default value.
            [headerTextWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:COVER_URL]]];
            // Scale for image.
            headerTextWebView.scalesPageToFit = YES;
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    moreInfoNavItem.title = self.title;
}

#pragma UIWebView delegate, open links in safari
-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

- (IBAction)dismissAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)homePageAction:(id)sender {
    NSString *homePageURL = @"http://www.weibo.com/u/3868827431"; // Weibo home page URL
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:homePageURL]];

}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"more_info_view_controller"];
}

@end
