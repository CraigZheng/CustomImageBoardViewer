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
        [self asynchrounslyHandleURL:url];
        isHandled = YES;
    }
    return isHandled;
}

+ (void)asynchrounslyHandleURL:(NSURL *)url {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"HEAD";
    NSString *hostPrefix = [settingCentre activeHost];
    [[czzAppDelegate sharedAppDelegate] showToast:@"请稍候..."];
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *finalURL;
            if (response.URL && error == nil) {
                finalURL = response.URL;
            } else {
                finalURL = url;
            }
            if (hostPrefix.length && [finalURL.absoluteString rangeOfString:hostPrefix options:NSCaseInsensitiveSearch].location != NSNotFound) {
                NSString *threadIDString = [finalURL.absoluteString stringByReplacingOccurrencesOfString:hostPrefix withString:@""];
                threadIDString = [threadIDString componentsSeparatedByString:@"/"].lastObject;
                NSInteger threadID = threadIDString.integerValue;
                if (threadID > 0) {
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
                } else {
                    [self openURL:finalURL];
                }
            } else {
                [self openURL:finalURL];
            }
        });
    }] resume];
}

+ (void)openURL:(NSURL *)url {
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    } else {
        [[czzAppDelegate sharedAppDelegate] showToast:@"无法打开链接……"];
    }
}
@end
