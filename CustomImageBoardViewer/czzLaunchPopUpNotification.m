//
//  czzLaunchPopUpNotification.m
//  CustomImageBoardViewer
//
//  Created by Craig on 24/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzLaunchPopUpNotification.h"

#import "UIApplication+Util.h"
#import "czzLaunchPopUpNotificationViewController.h"

static NSString * const kLastNotificationDisplayTime = @"kLastNotificationDisplayTime"; // Time when the notification was displayed.
static NSString * const kLastConfirmedNotificationTime = @"kLastConfirmedNotificationTime"; // Time of the last notification, used as an identifier.

@interface czzLaunchPopUpNotification() <czzLaunchPopUpNotificationViewControllerDelegate>
@end

@implementation czzLaunchPopUpNotification

- (instancetype)initWithJson:(NSString *)json {
    if (json.length) {
        NSError *error;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:NSJSONReadingMutableContainers
                                                                  error:&error];
        if (!error) {
            self = [super init];
            self.enable = [[jsonDict objectForKey:@"enable"] boolValue];
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.dateFormat = @"yyyyMMddhh";
            // The date field in the incoming json is a number, what a stupid design.
            NSString *dateString = @"";
            if ([[jsonDict objectForKey:@"date"] isKindOfClass:[NSString class]]) {
                dateString = [jsonDict objectForKey:@"date"];
            } else if ([[jsonDict objectForKey:@"date"] isKindOfClass:[NSNumber class]]) {
                dateString = [NSString stringWithFormat:@"%ld", (long)[[jsonDict objectForKey:@"date"] integerValue]];
            }
            NSDate *date = [formatter dateFromString:dateString];
            self.notificationDate = date;
            self.notificationContent = [jsonDict objectForKey:@"content"];
        } else {
            DLog(@"%@", error);
        }
    }
    return self;
}


#pragma mark - Showing - hiding.

- (Boolean)tryShow {
    Boolean shouldShow = NO;
    // Compare last show time with the current time.
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:kLastNotificationDisplayTime];
    NSDate *confirmedDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastConfirmedNotificationTime];
    // If the record date is present, and the notification date is smaller than this record date - don't show.
    if (date && [self.notificationDate compare:date] == NSOrderedAscending) {
        // Don't show, since the notificationDate is older than the record date.
        shouldShow = NO;
    } else {
        // notificationDate is still valid.
        shouldShow = YES;
        // If user has acknowledged that he wishes to see this notification no more, don't display it.
        if (confirmedDate && [self.notificationDate timeIntervalSince1970] == [confirmedDate timeIntervalSince1970]) {
            shouldShow = NO;
        }
    }
    // Only show when the app is running in the foreground.
    if (shouldShow && self.enable && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
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
    // Show time!
    NSDate *showTime = [NSDate new];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:showTime forKey:kLastNotificationDisplayTime];
    [userDefaults synchronize];
    // Show time!
    czzLaunchPopUpNotificationViewController *popUpViewController = [[UIStoryboard storyboardWithName:@"LaunchPopUpNotification"
                                                                      bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    popUpViewController.delegate = self;
    UIViewController *rootViewController = [UIApplication rootViewController];
    UIViewController *presentedViewController = rootViewController.presentedViewController;
    if (presentedViewController) {
        // If root view controller is already presenting a modal view controller, dismiss it, then present the pop up view controller.
        [rootViewController dismissViewControllerAnimated:NO completion:^{
            [rootViewController presentViewController:popUpViewController
                                             animated:YES completion:nil];
        }];
    } else {
        // Present the pop up view controller directly.
        popUpViewController.htmlContent = self.notificationContent;
        [rootViewController presentViewController:popUpViewController
                                         animated:YES
                                       completion:nil];
    }
}

- (void)hide {
    // If the currently presented modal view controller is a czzLaunchPopUpNotificationViewController, dismiss it.
    if ([[UIApplication rootViewController].presentedViewController isKindOfClass:[czzLaunchPopUpNotificationViewController class]]) {
        [[UIApplication rootViewController] dismissViewControllerAnimated:YES
                                                               completion:nil];
    }
}

#pragma mark - czzLaunchPopUpNotificationViewControllerDelegate

- (void)notificationViewController:(czzLaunchPopUpNotificationViewController *)viewController dismissedWithConfirmation:(BOOL)confirmed {
    if (confirmed) {
        // User confirmed that the notification is viewed.
        [[NSUserDefaults standardUserDefaults] setObject:self.notificationDate forKey:kLastConfirmedNotificationTime];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
