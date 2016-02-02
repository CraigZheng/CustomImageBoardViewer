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

#ifdef DEBUG
static NSInteger const refreshInterval = 60; // When debugging, every minute.
#else
    static NSInteger const refreshInterval = 60 * 5; // Every 5 minutes.
#endif
@interface czzWatchListManager ()

@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, strong) NSMutableOrderedSet *manuallyAddedThreads;
@property (nonatomic, strong) czzThreadViewManager *threadViewManager;
@property (nonatomic, strong) czzThreadDownloader *threadDownloader;

@end

@implementation czzWatchListManager

#pragma mark - Life cycle
-(instancetype)init {
    self = [super init];
    if (self) {
        [self restoreState];
        // Listen to app life cycle events.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    // Start the refresh timer.
    [self startTimer];
}

- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    // Stop the refresh timer.
    [self stopTimer];
}

- (void)startTimer {
    [self stopTimer];
    // Call the refresh method every designated time.
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:refreshInterval
                                                         target:self
                                                       selector:@selector(refreshWatchedThreadsInForeground)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)stopTimer {
    if (self.refreshTimer.isValid) {
        [self.refreshTimer invalidate];
    }
}

#pragma mark - Threads managements.
-(void)addToWatchList:(czzThread *)thread {
    [self.manuallyAddedThreads addObject:thread];
    [self saveState];
    
    // Permision for local notification - only when adding to the watchlist
    UIUserNotificationType types = UIUserNotificationTypeBadge |
    UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings =
    [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
}

-(void)removeFromWatchList:(czzThread *)thread {
    [self.manuallyAddedThreads removeObject:thread];
    [self saveState];
}

#pragma mark - Refresh action

- (void)refreshWatchedThreadsInForeground {
    [self refreshWatchedThreadsWithCompletionHandler:^(NSArray *updatedThreads) {
        DDLogDebug(@"%s: %ld threads updated in the foreground.", __PRETTY_FUNCTION__, (long)updatedThreads.count);
        [AppDelegate showToast:[NSString stringWithFormat:@"%ld thread(s) updated in background.", (long)updatedThreads.count]];
    }];
}

-(void)refreshWatchedThreadsWithCompletionHandler:(void (^)(NSArray *))completionHandler {
    if (self.isDownloading) {
        DDLogDebug(@"%@ is downloading, cannot proceed further...", NSStringFromClass(self.class));
        return;
    }
    if (!self.watchedThreads.count) {
        DDLogDebug(@"No currently watched threads, no need to refresh.");
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
                // If the updated thread has more replies than the recorded thread.
                if (newThread.responseCount > originalResponseCount) {
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
        if ([self.manuallyAddedThreads containsObject:thread]) {
            [self.manuallyAddedThreads removeObject:thread];
            [self.manuallyAddedThreads addObject:thread];
        }
    }
}

#pragma mark - State restoration
-(void)restoreState {
    @try {
        czzWatchListManager *tempWatchListManager = [NSKeyedUnarchiver unarchiveObjectWithFile:[[czzAppDelegate libraryFolder] stringByAppendingPathComponent:WATCH_LIST_CACHE_FILE]];
        if (tempWatchListManager && tempWatchListManager.watchedThreads.count) {
            self.manuallyAddedThreads = tempWatchListManager.manuallyAddedThreads;
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
    self.manuallyAddedThreads = [aDecoder decodeObjectForKey:@"manuallyAddedThreads"];
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.manuallyAddedThreads forKey:@"manuallyAddedThreads"];
}

#pragma mark - Getters
-(NSOrderedSet *)watchedThreads {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.manuallyAddedThreads];
    return [tempSet copy];
}

-(NSMutableOrderedSet *)manuallyAddedThreads {
    if (!_manuallyAddedThreads) {
        _manuallyAddedThreads = [NSMutableOrderedSet new];
    }
    // Set background fetch interval based on the count of threads being watched.
    if (_manuallyAddedThreads.count) {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
        DDLogDebug(@"Currently watched %ld threads.", (long)_manuallyAddedThreads.count);
    } else {
        // No thread is currently being watched, should never execute.
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
        DDLogDebug(@"No thread is being watched, set background fetch interval to never.");
    }

    return _manuallyAddedThreads;
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
