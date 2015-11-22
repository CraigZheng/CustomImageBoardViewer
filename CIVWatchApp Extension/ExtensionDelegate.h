//
//  ExtensionDelegate.h
//  CIVWatchApp Extension
//
//  Created by Craig Zheng on 19/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#define WKDelegate [ExtensionDelegate sharedInstance];

#import <WatchKit/WatchKit.h>

@class czzWatchKitCommand;

@protocol czzWKSessionDelegate <NSObject>
- (void)respondReceived:(NSDictionary *)response error:(NSError *)error;
@end

@interface ExtensionDelegate : NSObject <WKExtensionDelegate>
- (void)sendCommand:(czzWatchKitCommand *)command withCaller:(id<czzWKSessionDelegate>)caller;

+ (instancetype)sharedInstance;
@end
