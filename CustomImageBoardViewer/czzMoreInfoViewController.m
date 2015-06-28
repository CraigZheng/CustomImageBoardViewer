//
//  czzMoreInfoViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 29/11/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzMoreInfoViewController.h"
#import "SMXMLDocument.h"
#import "czzAppDelegate.h"
#import "czzSettingsCentre.h"
#import "Toast+UIView.h"
#import "czzForum.h"

@interface czzMoreInfoViewController ()<UIWebViewDelegate>
@property NSString *baseURL;
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
    bannerView_ = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    bannerView_.adUnitID = @"a152ad4b0262649";
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
}

-(void)renderContent {
    //position of the ad
    [bannerView_ setFrame:CGRectMake(0, self.view.bounds.size.height - bannerView_.bounds.size.height, bannerView_.bounds.size.width,
                                     bannerView_.bounds.size.height)];
    [bannerView_ loadRequest:[GADRequest request]];
    [self.view addSubview:bannerView_];
    //load forum info
    self.title = [NSString stringWithFormat:@"介绍：%@", self.forum.name];
    moreInfoNavItem.title = self.title;
    @try {
        NSString *headerText = [self.forum.header stringByReplacingOccurrencesOfString:@"@Time" withString:[NSString stringWithFormat:@"%ld", (long)self.forum.cooldown]];
        if (headerTextWebView.loading){
            [headerTextWebView stopLoading];
        }
        [headerTextWebView loadHTMLString:headerText baseURL:Nil];
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    
}

#pragma mark - setters
/*upon setting the forum name, this view controller should download relevent info from the server, 
 then put it in a web view
 */
-(void)setForum:(czzForum *)f {
    _forum = f;
    [self renderContent];
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

@end
