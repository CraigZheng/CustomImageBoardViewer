//
//  czzLaunchPopUpNotificationViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzLaunchPopUpNotificationViewController.h"
#import "czzURLHandler.h"
#import "czzLaunchPopUpNotification.h"

#import "SlideNavigationController.h"

static NSString * const kLastConfirmedNotificationKey = @"kLastConfirmedNotificationKey"; // Identifier of the last notification that the user confirmed has been viewed.

@interface czzLaunchPopUpNotificationViewController () <UIWebViewDelegate>
@property (weak, nonatomic) UIWebView *notificationWebView;
@property (weak, nonatomic) UISwitch *confirmSwitch;

@end

@implementation czzLaunchPopUpNotificationViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    return self;
}

- (void)loadView {
    UIView *rootView = [[UIView alloc] initWithFrame:CGRectZero];
    rootView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
    self.view = rootView;

    UIWebView *webView = [[UIWebView alloc] init];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.backgroundColor = [UIColor colorWithRed:0.290 green:0.315 blue:0.330 alpha:1];
    webView.delegate = self;
    [rootView addSubview:webView];
    self.notificationWebView = webView;

    UIView *switchContainer = [[UIView alloc] init];
    switchContainer.translatesAutoresizingMaskIntoConstraints = NO;
    switchContainer.backgroundColor = [UIColor whiteColor];
    [rootView addSubview:switchContainer];

    UIView *separator = [[UIView alloc] init];
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    separator.backgroundColor = [UIColor colorWithWhite:0.667 alpha:1];
    [switchContainer addSubview:separator];

    UISwitch *confirmSwitch = [[UISwitch alloc] init];
    confirmSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [confirmSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    [switchContainer addSubview:confirmSwitch];
    self.confirmSwitch = confirmSwitch;

    UILabel *confirmLabel = [[UILabel alloc] init];
    confirmLabel.translatesAutoresizingMaskIntoConstraints = NO;
    confirmLabel.text = @"我知道了";
    confirmLabel.textAlignment = NSTextAlignmentRight;
    confirmLabel.font = [UIFont systemFontOfSize:17];
    [switchContainer addSubview:confirmLabel];

    [rootView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnBackgroundAction:)]];

    UILayoutGuide *margins = rootView.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [webView.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
        [webView.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
        [webView.centerYAnchor constraintEqualToAnchor:rootView.centerYAnchor],
        [webView.heightAnchor constraintEqualToAnchor:rootView.heightAnchor multiplier:0.5],

        [switchContainer.topAnchor constraintEqualToAnchor:webView.bottomAnchor constant:-0.5],
        [switchContainer.leadingAnchor constraintEqualToAnchor:webView.leadingAnchor],
        [switchContainer.trailingAnchor constraintEqualToAnchor:webView.trailingAnchor],

        [separator.topAnchor constraintEqualToAnchor:switchContainer.topAnchor],
        [separator.leadingAnchor constraintEqualToAnchor:switchContainer.leadingAnchor],
        [separator.trailingAnchor constraintEqualToAnchor:switchContainer.trailingAnchor],
        [separator.heightAnchor constraintEqualToConstant:1],

        [confirmSwitch.topAnchor constraintEqualToAnchor:switchContainer.topAnchor constant:8],
        [switchContainer.bottomAnchor constraintEqualToAnchor:confirmSwitch.bottomAnchor constant:8],
        [switchContainer.trailingAnchor constraintEqualToAnchor:confirmSwitch.trailingAnchor constant:8],
        [confirmLabel.centerYAnchor constraintEqualToAnchor:confirmSwitch.centerYAnchor],
        [confirmSwitch.leadingAnchor constraintEqualToAnchor:confirmLabel.trailingAnchor constant:8],
        [confirmLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:switchContainer.leadingAnchor constant:8]
    ]];
}

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
        [czzURLHandler handleURL: request.URL];
        should = NO;
    }
    
    return should;
}

#pragma mark - Showing - hiding.

- (BOOL)tryShow {
    BOOL shouldShow = YES;
    NSString *confirmedNotificationIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:kLastConfirmedNotificationKey];
    // If the notification identifier has already been confirmed by the user, don't show.
    if (confirmedNotificationIdentifier.length && [self.popUpNotification.identifier isEqualToString:confirmedNotificationIdentifier]) {
        shouldShow = NO;
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
