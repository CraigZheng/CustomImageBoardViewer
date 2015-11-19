//
//  ExtensionDelegate.m
//  CIVWatchApp Extension
//
//  Created by Craig Zheng on 19/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "ExtensionDelegate.h"
@import WatchConnectivity;

@interface ExtensionDelegate() <WCSessionDelegate>

@end

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
    // Perform any final initialization of your application.
}

- (void)applicationDidBecomeActive {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
}

#pragma mark - WCSessionDelegate

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message {
    DLog(@"%s : %@", __PRETTY_FUNCTION__, message);
}

- (void)sessionReachabilityDidChange:(WCSession *)session {
    DLog(@"%s", __PRETTY_FUNCTION__);
    // TODO: phone not reachable.
}

+ (instancetype)sharedInstance {
    // Cast to id to suppress the Nullable warning.
    return (id)[WKExtension sharedExtension].delegate;
}

@end
