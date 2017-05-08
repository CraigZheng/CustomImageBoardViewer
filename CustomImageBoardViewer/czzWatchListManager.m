//
//  czzWatchListManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWatchListManager.h"
#import "czzThreadViewManager.h"
#import "czzFavouriteManager.h"
#import "czzBannerNotificationUtil.h"
#import "czzMessagePopUpViewController.h"
#import "czzFavouriteManagerViewController.h"

#import "CustomImageBoardViewer-Swift.h"

#define WATCH_LIST_CACHE_FILE @"watchedThreads.dat"

#ifdef DEBUG
static NSInteger const refreshInterval = 60; // When debugging, every minute.
#else
    static NSInteger const refreshInterval = 60 * 5; // Every 5 minutes.
#endif
static NSInteger const watchlistManagerLimit = 8; // It might take longer than the system allows to refresh anymore than this number.

@interface czzWatchListManager ()

@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, strong) NSMutableOrderedSet *manuallyAddedThreads;
@property (nonatomic, strong) czzThreadViewManager *threadViewManager;
@property (nonatomic, strong) czzThreadDownloader *threadDownloader;
@property (nonatomic, readonly) NSString *watchlistFilePath;
@property (nonatomic, assign) NSInteger downloadedCount;
@property (nonatomic, strong) NSDate *lastActiveRefreshTime;

@end

@implementation czzWatchListManager

#pragma mark - Life cycle
-(instancetype)init {
    self = [super init];
    if (self) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        // Make sure all cache files and folders are in place.
        // Folder.
        if (![fileManager fileExistsAtPath:self.watchlistFolder]){
            [fileManager createDirectoryAtPath:self.watchlistFolder
                   withIntermediateDirectories:NO
                                    attributes:@{NSFileProtectionKey:NSFileProtectionNone}
                                         error:nil];
            DDLogDebug(@"Create document folder: %@", self.watchlistFolder);
        } else {
            [fileManager setAttributes:@{NSFileProtectionKey:NSFileProtectionNone}
                          ofItemAtPath:self.watchlistFolder
                                 error:&error];
            if (error) {
                DLog(@"%@", error);
            }
        }
        // Cache file.
        if (![fileManager fileExistsAtPath:self.watchlistFilePath]) {
            // Not exists, create the necessary file.
            [fileManager createFileAtPath:self.watchlistFilePath
                                 contents:nil
                               attributes:@{NSFileProtectionKey:NSFileProtectionNone}];
        } else {
            // Exists, set attribute.
            [fileManager setAttributes:@{NSFileProtectionKey:NSFileProtectionNone}
                          ofItemAtPath:self.watchlistFilePath
                                 error:&error];
            if (error) {
                DLog(@"%@", error);
            }
        }

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
    // If never actively refresh before, or last active refresh time is 5 minutes ago.
    if (!self.lastActiveRefreshTime || [[NSDate new] timeIntervalSinceDate:self.lastActiveRefreshTime] > 5 * 60) {
        // Refresh upon activating.
        [self refreshWatchedThreadsInForeground];
        self.lastActiveRefreshTime = [NSDate new];
        // Start the refresh timer.
        [self startTimer];
    }
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
    // Safe guard.
    if (!thread) {
        return;
    }
    // Also adding it to the favourite manager.
    [favouriteManager addFavourite:thread];
    if (self.manuallyAddedThreads.count < watchlistManagerLimit) {
        [self.manuallyAddedThreads addObject:thread];
        [self saveState];
        
        // Permision for local notification - only when adding to the watchlist
        UIUserNotificationType types = UIUserNotificationTypeBadge |
        UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *mySettings =
        [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    } else {
        // Display an UIAlert to user, inform them they can not add anymore.
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"爆满啦"
                                                            message:[NSString stringWithFormat:@"你已注目了%ld个串，请清理后再添加！", (long)self.manuallyAddedThreads.count]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

-(void)removeFromWatchList:(czzThread *)thread {
    [self.manuallyAddedThreads removeObject:thread];
    [self saveState];
}

#pragma mark - Refresh action

- (void)refreshWatchedThreadsInForeground {
    [self refreshWatchedThreadsWithCompletionHandler:^(NSArray *updatedThreads) {
        DDLogDebug(@"%s: %ld threads updated in the foreground.", __PRETTY_FUNCTION__, (long)updatedThreads.count);
        // If updated threads is not empty, inform user by a notification.
        // This notification also allows user to tap on it to go straight to the favourite manager view controller.
        if (updatedThreads.count) {
            [MessagePopup showMessagePopupWithTitle:self.updateTitle
                                            message:self.updateContent
                                             layout:MessagePopupLayoutMessageView
                                              theme:MessagePopupThemeSuccess
                                           position:MessagePopupPresentationStyleBottom
                                        buttonTitle:@"查看"
                                buttonActionHandler:^(UIButton * _Nonnull button) {
                                    czzFavouriteManagerViewController *favouriteManagerViewController = [czzFavouriteManagerViewController new];
                                    favouriteManagerViewController.launchToIndex = watchIndex; // Launch to watchlist view.
                                    [NavigationManager pushViewController:favouriteManagerViewController
                                                                 animated:YES];
                                    [MessagePopup hide];
                                }];
        }
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
    
    // Since the content of watchedThreads might be mutabled, use its [self.watchedThreads copy] instead.
    NSDate *startDate = [NSDate new];
    self.downloadedCount = 0;
    NSInteger watchedCount = self.watchedThreads.count;
    for (czzThread *thread in [self.watchedThreads copy]) {
        if (thread.ID > 0) {
            // Each thread would be downloaded within its own background thread.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSInteger originalResponseCount = thread.responseCount;
                NSInteger originalThreadID = thread.ID;
                czzThread *newThread = [[czzThread alloc] initWithParentID:originalThreadID];
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Record the newly downloaded thread.
                    self.downloadedCount ++;
                    // If the updated thread has more replies than the recorded thread.
                    if (newThread.responseCount > originalResponseCount) {
                        [self.updatedThreads addObject:newThread];
                    }
                    // If self.downloadedThreads has same number of threads as self.watchedThreads, the downloading is completed.
                    if (self.downloadedCount >= watchedCount) {
                        [self updateWatchedThreadsWithThreads:self.updatedThreads];
                        self.isDownloading = NO;
                        DDLogDebug(@"%ld threads downloaded in %.1f seconds, %ld threads have new content", (long)self.watchedThreads.count, [[NSDate new] timeIntervalSinceDate:startDate], (long)self.updatedThreads.count);
                        completionHandler(self.updatedThreads);
                        [self saveState];
                        // Analytics.
                        id<GAITracker> defaultTracker = [[GAI sharedInstance] defaultTracker];
                        [defaultTracker send:[[GAIDictionaryBuilder createEventWithCategory:@"WatchList"
                                                                                     action:@"Updated"
                                                                                      label:[NSString stringWithFormat:@"Watching %ld threads", (long)watchedCount]
                                                                                      value:@(watchedCount)] build]];
                    }
                });
            });
        }
    }
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
        czzWatchListManager *tempWatchListManager = [NSKeyedUnarchiver unarchiveObjectWithFile:self.watchlistFilePath];
        if (tempWatchListManager && tempWatchListManager.watchedThreads.count) {
            self.manuallyAddedThreads = tempWatchListManager.manuallyAddedThreads;
            DLog(@"Watchlist restored.");
        }
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
    }
}

-(void)saveState {
    [NSKeyedArchiver archiveRootObject:self
                                toFile:self.watchlistFilePath];
    // Set background fetch interval based on the count of threads being watched.
    if (self.watchedThreads.count) {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    } else {
        // No thread is currently being watched, should never execute.
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    }
    DDLogDebug(@"%s: %ld threads.", __PRETTY_FUNCTION__, (long)self.watchedThreads.count);
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

- (NSString *)watchlistFolder {
    NSString *watchlistFolder = [[czzAppDelegate documentFolder] stringByAppendingPathComponent:@"Watchlist"];
    return watchlistFolder;
}

- (NSString *)watchlistFilePath {
    NSString *watchlistFilePath = [self.watchlistFolder stringByAppendingPathComponent:WATCH_LIST_CACHE_FILE];
    return watchlistFilePath;
}

- (NSString *)updateSummary {
    if (self.updatedThreads.count) {
        NSString *updateSummary = [NSString stringWithFormat:@"%@\n%@", self.updateTitle, self.updateContent];
        return updateSummary;
    }
    return @"";
}

- (NSString *)updateTitle {
    if (self.updatedThreads.count) {
        return @"注目的串有新内容！";
    }
    return @"";
}

- (NSString *)updateContent {
    if (self.updatedThreads.count) {
        NSMutableString *contentSummary = [NSMutableString new];
        NSInteger summariedContent = 0;
        for (czzThread *thread in self.updatedThreads) {
            [contentSummary appendFormat:@"%@\n", thread.contentSummary];
            summariedContent ++;
            // Don't summarise more than 3.
            if (summariedContent >= 3) {
                break;
            }
        }
        NSString *updateContent = [NSString stringWithFormat:@"%ld个串有新回复：%@", (long)self.updatedThreads.count, contentSummary];
        return updateContent;
    }
    return @"";
}

-(NSOrderedSet *)watchedThreads {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.manuallyAddedThreads];
    return [tempSet copy];
}

-(NSMutableOrderedSet *)manuallyAddedThreads {
    if (!_manuallyAddedThreads) {
        _manuallyAddedThreads = [NSMutableOrderedSet new];
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
