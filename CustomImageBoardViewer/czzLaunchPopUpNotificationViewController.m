//
//  czzLaunchPopUpNotificationViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzLaunchPopUpNotificationViewController.h"

@interface czzLaunchPopUpNotificationViewController () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *notificationWebView;
@property (weak, nonatomic) IBOutlet UISwitch *confirmSwitch;

@end

@implementation czzLaunchPopUpNotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Pass html content to the web view.
    if (self.htmlContent.length) {
        [self.notificationWebView loadHTMLString:_htmlContent
                                         baseURL:nil];
    }
}

#pragma mark - UI actions.

- (IBAction)tapOnBackgroundAction:(id)sender {
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 if (self.completionHandler) {
                                     self.completionHandler();
                                 }
                                 if ([self.delegate respondsToSelector:@selector(notificationViewController:dismissedWithConfirmation:)]) {
                                     [self.delegate notificationViewController:self dismissedWithConfirmation:self.confirmSwitch.isOn];
                                 }
                             }];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL should = YES;
    // Open browser for any link.
    if ([[UIApplication sharedApplication] canOpenURL:request.URL]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        should = NO;
    }
    
    return should;
}

@end
