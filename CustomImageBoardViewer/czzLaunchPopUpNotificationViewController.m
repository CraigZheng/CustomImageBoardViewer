//
//  czzLaunchPopUpNotificationViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzLaunchPopUpNotificationViewController.h"

#import "czzLaunchPopUpNotification.h"

static NSString * const kLastConfirmedNotificationKey = @"kLastConfirmedNotificationKey"; // Identifier of the last notification that the user confirmed has been viewed.

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
- (IBAction)switchValueChanged:(id)sender {
    if (self.confirmSwitch.isOn) {
        [self tapOnBackgroundAction:sender];
    }
}

- (IBAction)tapOnBackgroundAction:(id)sender {
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 if (self.completionHandler) {
                                     self.completionHandler();
                                 }
                                 if (self.confirmSwitch.isOn) {
                                     [[NSUserDefaults standardUserDefaults] setObject:self.popUpNotification.identifier
                                                                               forKey:kLastConfirmedNotificationKey];
                                     [[NSUserDefaults standardUserDefaults] synchronize];
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

#pragma mark - Showing - hiding.

- (Boolean)tryShow {
    Boolean shouldShow = NO;
    NSString *confirmedNotificationIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:kLastConfirmedNotificationKey];
    // If the notification identifier has already been confirmed by the user, don't show.
    if ([self.popUpNotification.notificationDate compare:[NSDate new]] == NSOrderedAscending) {
        shouldShow = NO;
    } else {
        // notificationDate is still valid.
        shouldShow = YES;
        // If user has acknowledged that he wishes to see this notification no more, don't display it.
        if (confirmedNotificationIdentifier.length && [self.popUpNotification.identifier isEqualToString:confirmedNotificationIdentifier]) {
            shouldShow = NO;
        }
    }
    // Only show when the app is running in the foreground.
    if (shouldShow && self.popUpNotification.enable && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        if ([[SlideNavigationController sharedInstance] isMenuOpen]) {
            [[SlideNavigationController sharedInstance] closeMenuWithCompletion:^{
                [self show];
            }];
        } else {
            [self show];
        }
        shouldShow = YES;
    } else {
        shouldShow = NO;
    }
    return shouldShow;
}

- (void)show {
    // Present self on the root view controller.
    UIViewController *rootViewController = [UIApplication rootViewController];
    UIViewController *presentedViewController = rootViewController.presentedViewController;
    if (presentedViewController) {
        // If root view controller is already presenting a modal view controller, dismiss it, then present the pop up view controller.
        [rootViewController dismissViewControllerAnimated:NO completion:^{
            [rootViewController presentViewController:self
                                             animated:YES completion:nil];
        }];
    } else {
        // Present the pop up view controller directly.
        self.htmlContent = self.popUpNotification.notificationContent;
        [rootViewController presentViewController:self
                                         animated:YES
                                       completion:nil];
    }
}

@end
