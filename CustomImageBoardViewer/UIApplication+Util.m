//
//  UIApplication+Util.m
//  CashByOptusPhone
//
//  Created by Craig on 26/02/2015.
//  Copyright (c) 2015 Singtel Optus Pty Ltd. All rights reserved.
//

#import "UIApplication+Util.h"

@implementation UIApplication (Util)

+(UIViewController *)topViewController {
    UIViewController *topViewController = [UIApplication rootViewController].presentedViewController;
    //if rootview controller is UINavigationController, it will have no presentedViewController
    if (!topViewController)
    {
        if ([[UIApplication rootViewController] isKindOfClass:[UINavigationController class]]) {
            topViewController = [(UINavigationController*) [UIApplication rootViewController] viewControllers].lastObject;
        } else
            topViewController = [UIApplication rootViewController];
    }
    //find the top most view controller
    while (topViewController && topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

+(UIViewController *)rootViewController {
    UIApplication *sharedApplication = [UIApplication sharedApplication];
    UIViewController *rootViewController;
    if (sharedApplication)
    {
        rootViewController = [[sharedApplication keyWindow] rootViewController];
    }
    return rootViewController;
}

+(NSString *)bundleVersion{
    NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

    return [NSString stringWithFormat:@"%@-%@", bundleIdentifier, versionString];
}

+(NSString *)appId {
    return [NSString stringWithFormat:@"%@", @"A-Island-IOS-App"];
}
@end
