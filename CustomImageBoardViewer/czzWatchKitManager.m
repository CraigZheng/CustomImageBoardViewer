//
//  czzWatchKitManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 18/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWatchKitManager.h"
#import "czzWatchKitCommand.h"

@interface czzWatchKitManager () <czzHomeViewModelManagerDelegate>
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (copy)void (^reply)(NSDictionary *replyDictionary);
@end

@implementation czzWatchKitManager

-(void)handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply withBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier{
    self.backgroundTaskIdentifier = backgroundTaskIdentifier;
    self.reply = reply;
    if ([[userInfo objectForKey:@"COMMAND"]  isEqual: @(watchKitCommandLoadHomeView)]) {
        [self watchKitLoadHomeView];
    }
}

-(void)watchKitLoadHomeView {
    czzHomeViewModelManager *homeViewModelManager = [czzHomeViewModelManager sharedManager];
    
    if (homeViewModelManager.threads.count) {
        [self replyWithDictionary:(@{@(watchKitCommandLoadHomeView) : [self watchKitThreadsWithThreads:homeViewModelManager.threads],
                        @(watchKitMiscInfoScreenTitleHome) : homeViewModelManager.forum.name.length ? homeViewModelManager.forum.name : @"不知道"})];
    } else {
        __weak typeof(homeViewModelManager) weakHomeViewModelManager = homeViewModelManager; // To suppress the warning of having strong reference in a block.
        homeViewModelManager.watchKitCompletionHandler = ^(BOOL success, NSArray *threads) {
            if (success) {
                //TODO: if success? if fail?
            }
            NSDictionary *wkThreads = @{@(watchKitCommandLoadHomeView) : [self watchKitThreadsWithThreads:threads],
                                        @(watchKitMiscInfoScreenTitleHome) : weakHomeViewModelManager.forum.name.length ? weakHomeViewModelManager.forum.name : @"不知道"};
            [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"Passing %ld objects to watch kit...", (long)wkThreads.allValues.count]];
            [self replyWithDictionary:wkThreads];
        };
        [[czzAppDelegate sharedAppDelegate] showToast:@"Downloading for watch kit..."];
        [homeViewModelManager refresh];
        
    }
}

-(void)replyWithDictionary:(NSDictionary *)dict {
    if (self.reply) {
        self.reply(dict);
        self.reply = nil;
    }
    [self endBackgroundTask];
}

-(void)endBackgroundTask {
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        }
    }];
}

-(NSArray *)watchKitThreadsWithThreads:(NSArray *)threads {
    NSMutableArray *wkThreads = [NSMutableArray new];
    for (czzThread* thread in threads) {
        [wkThreads addObject:[[thread watchKitThread] encodeToDictionary]];
    }
    
#ifdef DEBUG
    // Load from cache
    NSString *wkThreadCache = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:@"wkCaches.dat"];
    if (!wkThreads.count) {
        wkThreads = [NSKeyedUnarchiver unarchiveObjectWithFile:wkThreadCache];
    } else {
        [NSKeyedArchiver archiveRootObject:wkThreads toFile:wkThreadCache];
    }
    
    
#endif

    return wkThreads;
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
