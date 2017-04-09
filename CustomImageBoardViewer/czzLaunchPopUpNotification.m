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
#import "CustomImageBoardViewer-Swift.h"

static NSString * const kLastNotificationDisplayTime = @"kLastNotificationDisplayTime";

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

- (BOOL)tryShow {
    BOOL shouldShow = [self shouldShow];
    // Only show when the app is running in the foreground.
    if (shouldShow) {
        if ([[SlideNavigationController sharedInstance] isMenuOpen]) {
            [[SlideNavigationController sharedInstance] closeMenuWithCompletion:^{
                [self show];
            }];
        } else {
            [self show];
        }
    } else {
        [NSNotificationCenter.defaultCenter postNotificationName:AppLaunchManager.eventCompleted object:nil];
    }
    return shouldShow;
}

- (BOOL)shouldShow {
    BOOL shouldShow = NO;
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:kLastNotificationDisplayTime];
    // If the record date is present, and notification date is older than this date - don't show.
    if (date && [self.notificationDate compare:date] == NSOrderedAscending) {
        // Don't show, since the notificationDate is older than the record date.
        shouldShow = NO;
    } else {
        shouldShow = self.enable && [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
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
    popUpViewController.completionHandler = ^{
        [NSNotificationCenter.defaultCenter postNotificationName:AppLaunchManager.eventCompleted object:nil];
    };
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

@end
