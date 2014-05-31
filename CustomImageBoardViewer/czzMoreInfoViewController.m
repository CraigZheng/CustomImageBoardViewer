//
//  czzMoreInfoViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 29/11/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzMoreInfoViewController.h"
#import "czzXMLDownloader.h"
#import "SMXMLDocument.h"
#import "czzAppDelegate.h"
#import "Toast+UIView.h"

@interface czzMoreInfoViewController ()<czzXMLDownloaderDelegate, UIWebViewDelegate>
@property czzXMLDownloader *xmlDownloader;
@property NSString *baseURL;
@end

@implementation czzMoreInfoViewController
@synthesize headerTextWebView;
@synthesize xmlDownloader;
@synthesize baseURL;
@synthesize forumName;
@synthesize bannerView_;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    baseURL = @"http://h.acfun.tv/api/forum/get?forumName=";
    //admob module
    bannerView_ = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    bannerView_.adUnitID = @"a151ef285f8e0dd";
    bannerView_.rootViewController = self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //position of the ad
    [bannerView_ setFrame:CGRectMake(0, self.view.bounds.size.height - bannerView_.bounds.size.height, bannerView_.bounds.size.width,
                                     bannerView_.bounds.size.height)];
    [bannerView_ loadRequest:[GADRequest request]];
    [self.view addSubview:bannerView_];
}

/*upon setting the forum name, this view controller should download relevent info from the server, 
 then put it in a web view
 */
-(void)setForumName:(NSString *)forumname{
    forumName = forumname;
    self.title = [NSString stringWithFormat:@"介绍：%@",forumname];
    //if the previous downloader hasn't been finished, stop it
    if (xmlDownloader){
        [xmlDownloader stop];
    }
    //create a new xml downloader with given forum name and api
    NSString *targetURL = [baseURL stringByAppendingString:[self.forumName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [NSURL URLWithString:targetURL];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:url delegate:self startNow:YES];
    
}

#pragma czzXMLDownloader delegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData{
    if (successed){
        NSError *error;
        SMXMLDocument *xmlDoc = [[SMXMLDocument alloc] initWithData:xmlData error:&error];
        if (error){
            NSLog(@"%@", error);
            return;
        }
        NSString *headerText = @"";
        NSInteger sendTime = 0;
        for (SMXMLElement *child in xmlDoc.root.children) {
            if ([child.name isEqualToString:@"status"]){
                NSInteger status = [child.value integerValue];
                if (status != 200)
                    return;
            }
            if ([child.name isEqualToString:@"model"]){
                //create a thread outta this xml data
                for (SMXMLElement *childNode in child.children) {
                    if ([childNode.name isEqualToString:@"HeaderText"]){
                        headerText = childNode.value;
                    }
                    if ([childNode.name isEqualToString:@"SendTimeSpan"]){
                        sendTime = [childNode.value integerValue];
                    }
                }
            }
            

        }
        //inject the time span
        headerText = [headerText stringByReplacingOccurrencesOfString:@"@Time" withString:[NSString stringWithFormat:@"%d", sendTime]];
        if (headerTextWebView.loading){
            [headerTextWebView stopLoading];
        }
        [headerTextWebView loadHTMLString:headerText baseURL:Nil];

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

- (IBAction)homePageAction:(id)sender {
    NSString *homePageURL = @"http://www.acfun.tv/u/712573.aspx";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:homePageURL]];

}

@end
