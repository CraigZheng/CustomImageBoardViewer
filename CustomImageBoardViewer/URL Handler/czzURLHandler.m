//
//  czzURLHandler.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzURLHandler.h"

#import "czzSettingsCentre.h"
#import "czzHomeViewManager.h"
#import "czzAppDelegate.h"

@implementation czzURLHandler

+ (BOOL)handleURL:(NSURL *)url {
    BOOL isHandled = NO;
    if (url) {
        NSString *hostPrefix = [settingCentre a_isle_host];
        if (hostPrefix.length && [url.absoluteString rangeOfString:hostPrefix options:NSCaseInsensitiveSearch].location != NSNotFound) {
            NSString *threadIDString = [url.absoluteString stringByReplacingOccurrencesOfString:hostPrefix withString:@""];
            threadIDString = [threadIDString componentsSeparatedByString:@"/"].lastObject;
            NSInteger threadID = threadIDString.integerValue;
            if (threadID > 0) {
                isHandled = YES;
                // Get the thread with the given ID from server.
                [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"正在下载: %ld", (long)threadID]];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    czzThread * thread = [[czzThread alloc] initWithThreadID:threadID];
                    // After return, run the remaining codes in main thread.
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (thread) {
                            [[czzHomeViewManager sharedManager] showContentWithThread:thread];
                        } else {
                            [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"找不到引用串：%ld", (long)thread.ID]];
                        }
                    });
                });
            }
        } else {
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
                isHandled = YES;
            }
        }
    }
    return isHandled;
}
@end
