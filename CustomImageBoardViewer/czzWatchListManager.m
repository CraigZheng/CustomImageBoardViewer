//
//  czzWatchListManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWatchListManager.h"
#import "czzThreadViewManager.h"
#import "czzMessagePopUpViewController.h"

#define WATCH_LIST_CACHE_FILE @"watchedThreads.dat"

@interface czzWatchListManager ()

@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, strong) czzThreadViewManager *threadViewManager;
@end

@implementation czzWatchListManager

#pragma mark - Life cycle
-(instancetype)init {
    self = [super init];
    if (self) {
        [self restoreState];
        
    }
    
    return self;
}


-(void)addToWatchList:(czzThread *)thread {
    [self.watchedThreads addObject:thread];
    [self saveState];
    
    // Permision for local notification - only when adding to the watchlist
    UIUserNotificationType types = UIUserNotificationTypeBadge |
    UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings =
    [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
}

-(void)removeFromWatchList:(czzThread *)thread {
    [self.watchedThreads removeObject:thread];
    [self saveState];
}

#pragma mark - Refresh action
-(void)refreshWatchedThreads:(void (^)(NSArray *))completionHandler {
    if (self.isDownloading) {
        DDLogDebug(@"%@ is downloading, cannot proceed further...", NSStringFromClass(self.class));
        return;
    }
    DDLogDebug(@"Watchlist manager refreshing watched threads...");
    self.isDownloading = YES;
    self.updatedThreads = [NSMutableArray new];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // Since the content of watchedThreads might be mutabled, use its [self.watchedThreads copy] instead.
        NSDate *startDate = [NSDate new];
        
        for (czzThread *thread in [self.watchedThreads copy]) {
            if (thread.ID > 0) {
                NSInteger originalResponseCount = thread.responseCount;
                NSInteger originalThreadID = thread.ID;
                czzThread *newThread = [[czzThread alloc] initWithParentID:originalThreadID];
                
                if (originalResponseCount > newThread.responseCount) {
                    //Record the old thread with old data, later we will remove it from the OrderedSet, then put it back to update the set.
                    [self.updatedThreads addObject:newThread];
                }
            }
        }
        [self updateWatchedThreadsWithThreads:self.updatedThreads];
        self.isDownloading = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            DDLogDebug(@"%ld threads downloaded in %.1f seconds, %ld threads have new content", (long)self.watchedThreads.count, [[NSDate new] timeIntervalSinceDate:startDate], (long)self.updatedThreads.count);
            completionHandler(self.updatedThreads);
            [self saveState];
        });
    });
}

-(void)updateWatchedThreadsWithThreads:(NSArray*)updatedThreads {
    for (czzThread *thread in updatedThreads) {
        [self.watchedThreads removeObject:thread];
        [self.watchedThreads addObject:thread];
    }
}

#pragma mark - State restoration
-(void)restoreState {
    @try {
        czzWatchListManager *tempWatchListManager = [NSKeyedUnarchiver unarchiveObjectWithFile:[[czzAppDelegate libraryFolder] stringByAppendingPathComponent:WATCH_LIST_CACHE_FILE]];
        if (tempWatchListManager && tempWatchListManager.watchedThreads.count) {
            self.watchedThreads = tempWatchListManager.watchedThreads;
        }
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
    }
}

-(void)saveState {
    [NSKeyedArchiver archiveRootObject:self toFile:[[czzAppDelegate libraryFolder] stringByAppendingPathComponent:WATCH_LIST_CACHE_FILE]];
}

#pragma mark - NSCodingDelegate
-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    self.watchedThreads = [aDecoder decodeObjectForKey:@"watchedThreads"];
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.watchedThreads forKey:@"watchedThreads"];
}

#pragma mark - Getters
-(NSMutableOrderedSet *)watchedThreads {
    if (!_watchedThreads) {
        _watchedThreads = [NSMutableOrderedSet new];
    }
    // Set background fetch interval based on the count of threads being watched.
    if (_watchedThreads.count) {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    } else {
        // No thread is currently being watched, should never execute.
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    }
    return _watchedThreads;
}

+(instancetype)sharedManager {
    static id sharedManager;
    static dispatch_once_t once_token;
    
    dispatch_once(&once_token, ^{
        sharedManager = [czzWatchListManager new];
    });
    
    return sharedManager;
}
@end
