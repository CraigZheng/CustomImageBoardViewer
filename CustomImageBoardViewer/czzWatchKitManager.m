//
//  czzWatchKitManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 18/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWatchKitManager.h"
#import "czzWatchKitCommand.h"
#import "czzThreadViewModelManager.h"

@interface czzWatchKitManager () <czzHomeViewModelManagerDelegate>
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (copy)void (^reply)(NSDictionary *replyDictionary);
@end

@implementation czzWatchKitManager

-(void)handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply withBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier{
    self.backgroundTaskIdentifier = backgroundTaskIdentifier;
    self.reply = reply;
    id command = [userInfo objectForKey:@"COMMAND"];
    if ([command isEqual: @(watchKitCommandLoadHomeView)]) {
        [self watchKitLoadHomeView];
    } else if ([command isEqual:@(watchKitCommandLoadThreadView)]) {
        czzWKThread *selectedThread = [[czzWKThread alloc] initWithDictionary:[userInfo objectForKey:@"THREAD"]];
        if (selectedThread) {
            [self watchKitLoadThreadView:selectedThread];
        }
    }
}

-(void)watchKitLoadHomeView {
    czzHomeViewModelManager *homeViewModelManager = [czzHomeViewModelManager sharedManager];
    
    __block NSMutableDictionary *replyDictionary = [NSMutableDictionary new];
    
    [replyDictionary addEntriesFromDictionary:@{@(watchKitMiscInfoScreenTitleHome) : homeViewModelManager.forum.name.length ? homeViewModelManager.forum.name : @"没有板块"}];
    if (homeViewModelManager.threads.count) {
        [replyDictionary addEntriesFromDictionary:@{@(watchKitCommandLoadHomeView) : [self watchKitThreadsWithThreads:homeViewModelManager.threads]}];
        [self replyWithDictionary: replyDictionary];
    } else {
        homeViewModelManager.watchKitCompletionHandler = ^(BOOL success, NSArray *threads) {
            if (success) {
                //TODO: if success? if fail?
            }
            [replyDictionary addEntriesFromDictionary:@{@(watchKitCommandLoadHomeView) : [self watchKitThreadsWithThreads:threads]}];
            [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"Passing %ld objects to watch kit...", (long)replyDictionary.allValues.count]];
            [self replyWithDictionary:replyDictionary];
        };
        [[czzAppDelegate sharedAppDelegate] showToast:@"Downloading for watch kit..."];
        [homeViewModelManager refresh];
        
    }
}

-(void)watchKitLoadThreadView:(czzWKThread*)selectedThread {
    czzThread *parentThread = [[czzThread alloc] initWithThreadID:selectedThread.ID];
    czzThreadViewModelManager *threadViewModelManager = [[czzThreadViewModelManager alloc] initWithParentThread:parentThread andForum:nil];
    
    [threadViewModelManager restorePreviousState];
    if (threadViewModelManager.threads.count) {
        NSDictionary *replyDictionary = @{@(watchKitCommandLoadThreadView) : [self watchKitThreadsWithThreads:threadViewModelManager.threads]};
        [self replyWithDictionary:replyDictionary];
    } else {
        __weak typeof (threadViewModelManager) weakThreadViewModelManager = threadViewModelManager;
        threadViewModelManager.watchKitCompletionHandler = ^(BOOL success, NSArray *threads) {
            NSDictionary *replyDictionary = @{@(watchKitCommandLoadThreadView) : [self watchKitThreadsWithThreads:weakThreadViewModelManager.threads]};
            [self replyWithDictionary:replyDictionary];
        };
        
        [threadViewModelManager refresh];
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
