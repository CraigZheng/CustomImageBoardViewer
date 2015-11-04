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
#import "czzImageViewerUtil.h"

@interface czzMoreInfoViewController ()<UIWebViewDelegate>
@property (strong, nonatomic) NSString *baseURL;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;
@property NSData *coverData;
@end

@implementation czzMoreInfoViewController
@synthesize headerTextWebView;
@synthesize baseURL;
@synthesize bannerView_;
@synthesize moreInfoNavItem;

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
}

-(void)renderContent {
    //position of the ad
    [bannerView_ setFrame:CGRectMake(0, self.view.bounds.size.height - bannerView_.bounds.size.height, bannerView_.bounds.size.width,
                                     bannerView_.bounds.size.height)];
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
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSError *error;
                self.coverData = [NSData dataWithContentsOfURL:[NSURL URLWithString:COVER_URL] options:NSDataReadingUncached error:&error];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!error) {
                        [headerTextWebView loadData:self.coverData MIMEType:@"image/jpeg" textEncodingName:@"utf-8" baseURL:[NSURL new]];
                    } else {
                         self.coverData = nil;
                        [headerTextWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:COVER_URL]]];
                    }
                });
            });
            // Scale for image.
            headerTextWebView.scalesPageToFit = YES;
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    moreInfoNavItem.title = self.title;
}

#pragma mark - UI actions
- (IBAction)actionButtonAction:(id)sender {
    if (self.coverData) {
        UIImage *coverImage = [UIImage imageWithData:self.coverData];
        [[czzImageViewerUtil new] showPhotoWithImage:coverImage];
    }
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
