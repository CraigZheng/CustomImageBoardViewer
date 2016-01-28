//
//  ExtensionDelegate.m
//  CIVWatchApp Extension
//
//  Created by Craig Zheng on 19/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "ExtensionDelegate.h"
#import "czzWatchKitCommand.h"

@import WatchConnectivity;

@interface ExtensionDelegate() <WCSessionDelegate>
@property (weak) id<czzWKSessionDelegate> weakRefCaller;

@end

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
}

- (void)applicationDidBecomeActive {
    DLog(@"%s", __PRETTY_FUNCTION__);
    if ([WCSession isSupported]) {
        [WCSession defaultSession].delegate = self;
        [[WCSession defaultSession] activateSession];
    }
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
}

#pragma mark - Message delivery.
- (void)sendCommand:(czzWatchKitCommand *)command withCaller:(id<czzWKSessionDelegate>)caller {
    DLog(@"%s", __PRETTY_FUNCTION__);
    DLog(@"%@.%ld", command.caller, (long)command.action);
    DLog(@"%@", command.parameter);
    
    self.weakRefCaller = caller;
    [[WCSession defaultSession] updateApplicationContext:command.encodeToDictionary error:nil];
    
//    [[WCSession defaultSession] sendMessage:command.encodeToDictionary replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
//        DLog(@"%@", replyMessage);
//        [weakRefCaller respondReceived:replyMessage error:nil];
//    } errorHandler:^(NSError * _Nonnull error) {
//        DLog(@"%@", error);
//        [weakRefCaller respondReceived:nil error:error];
//    }];
}

- (void)session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext {
    [self.weakRefCaller respondReceived:applicationContext error:nil];
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
