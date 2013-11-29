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
#import <MessageUI/MFMailComposeViewController.h>

@interface czzMoreInfoViewController ()<czzXMLDownloaderDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate>
@property czzXMLDownloader *xmlDownloader;
@property NSString *baseURL;
@end

@implementation czzMoreInfoViewController
@synthesize headerTextWebView;
@synthesize xmlDownloader;
@synthesize baseURL;
@synthesize forumName;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    baseURL = @"http://h.acfun.tv/api/forum/get?forumName=";
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

//send an email to me
- (IBAction)sendEmailAction:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        [controller setToRecipients:[NSArray arrayWithObject:@"craignineten@gmail.com"]];
        [controller setSubject:@"A岛客户端无图版意见反馈"];
        [controller setMessageBody:@"" isHTML:NO];
        if (controller) [self presentViewController:controller animated:YES completion:nil];
        [self.viewDeckController toggleTopViewAnimated:YES];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"ERROR" message:@"EMAIL NOT READY" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }
}

- (IBAction)homePageAction:(id)sender {
    NSString *homePageURL = @"http://www.acfun.tv/u/712573.aspx";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:homePageURL]];

}

#pragma MFMailComposeViewController delegate
-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
