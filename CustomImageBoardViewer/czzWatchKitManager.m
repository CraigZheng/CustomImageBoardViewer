//
//  czzWatchKitManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 18/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWatchKitManager.h"

@interface czzWatchKitManager () <czzHomeViewModelManagerDelegate>

@end

@implementation czzWatchKitManager

-(void)handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply{
    czzHomeViewModelManager *homeViewModelManager = [czzHomeViewModelManager sharedManager];

    if (homeViewModelManager.threads.count && NO) {
        reply([self watchKitThreadsWithThreads:homeViewModelManager.threads]);
    } else {
        homeViewModelManager.watchKitCompletionHandler = ^(BOOL success, NSArray *threads) {
            if (success) {
                //TODO: if success? if fail?
            }
            reply([self watchKitThreadsWithThreads:threads]);
        };
        [homeViewModelManager refresh];
        
    }
}

-(NSDictionary *)watchKitThreadsWithThreads:(NSArray *)threads {
    NSMutableArray *wkThreads = [NSMutableArray new];
    for (czzThread* thread in threads) {
        [wkThreads addObject:[thread watchKitThread]];
    }

    return @{@"HOME_VIEW_THREADS" : wkThreads};
}

+(instancetype)sharedManager {
    static dispatch_once_t once_token;
    static id sharedManager;
    if (!sharedManager) {
        dispatch_once(&once_token, ^{
            sharedManager = [czzWatchKitManager new];
        });
    }
    return sharedManager;
}

@end
