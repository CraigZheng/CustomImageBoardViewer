//
//  czzSubThreadList.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//
#define settingCentre [czzSettingsCentre sharedInstance]

#import "czzThreadViewManager.h"
#import "czzHistoryManager.h"
#import "czzWatchListManager.h"
#import "czzThreadDownloader.h"
#import "czzMassiveThreadDownloader.h"
#import "czzMarkerManager.h"

@interface czzThreadViewManager() <czzMassiveThreadDownloaderDelegate>
@property (nonatomic, assign) BOOL pageNumberChanged;
@property (nonatomic, strong) czzMassiveThreadDownloader *massiveDownloader;
@end

@implementation czzThreadViewManager
@synthesize forum = _forum;
@synthesize downloader = _downloader;
@synthesize threads = _threads;
@dynamic delegate;

#pragma mark - life cycle.
-(instancetype)initWithParentThread:(czzThread *)thread andForum:(czzForum *)forum{
    self = [self init];
    if (self) {
        // Record history
        self.parentThread = thread;
        if (self.parentThread)
            [historyManager recordThread:self.parentThread];
        // Give it a default forum, can be nil.
        self.forum = forum ?: [czzForum new];

        [self reset];
    }
    
    return self;
}

-(instancetype)restoreWithFile:(NSString *)filePath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        czzThreadViewManager *tempThreadList = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        //copy data
        if (tempThreadList && [tempThreadList isKindOfClass:[czzThreadViewManager class]])
        {
            return tempThreadList;
        }
    }
    return nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - state perserving/restoring
-(void)restorePreviousState {
    NSString *cacheFile = [[czzAppDelegate threadCacheFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld%@", (long)self.parentThread.ID, SUB_THREAD_LIST_CACHE_FILE]];
    @try {
        // If user doesn't want to use cache, don't attempt to restore.
        if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
            czzThreadViewManager *tempThreadList = [self restoreWithFile:cacheFile];
            // Copy data, only restore it when the tempThreadList has more than 1 thread(counting the parent thread).
            if ([tempThreadList isKindOfClass:[czzThreadViewManager class]]
                && tempThreadList.threads.count > 1)
            {
                _parentThread = tempThreadList.parentThread; // Since there's a custom setter in this class, its better not to invoke it.
                self.pageNumber = tempThreadList.pageNumber;
                self.totalPages = tempThreadList.totalPages;
                self.threads = tempThreadList.threads;
                self.currentOffSet = tempThreadList.currentOffSet;
                self.lastBatchOfThreads = tempThreadList.lastBatchOfThreads;
                self.shouldHideImageForThisForum = tempThreadList.shouldHideImageForThisForum;
                self.restoredFromCache = YES;
                return;
            }
        }
        self.restoredFromCache = NO;
    }
    @catch (NSException *exception) {
        [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
        DDLogDebug(@"%@", exception);
    }
}

-(NSString*)saveCurrentState {
    DLog(@"");
    NSString *cachePath = [[czzAppDelegate threadCacheFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld%@", (long)self.parentThread.ID, SUB_THREAD_LIST_CACHE_FILE]];
    if ([NSKeyedArchiver archiveRootObject:self toFile:cachePath]) {
        return cachePath;
    }
    return nil;
}

#pragma mark - setters
-(void)setParentThread:(czzThread *)thread {
    if (thread) {
        _parentThread = thread;
        self.parentID = [NSString stringWithFormat:@"%ld", (long)self.parentThread.ID];
        // When setting the parent thread, see if the downloaded parent thread is included in the watchlist manager.
        // If it is, then update the corresponding thread in watchlist manager.
        if ([WatchListManager.watchedThreads containsObject:_parentThread]) {
            DDLogDebug(@"Parent thread is being watched, update Watchlist manager...");
            // Remove the recorded thread, add the new thread.
            [WatchListManager removeFromWatchList:_parentThread];
            [WatchListManager addToWatchList:_parentThread];
        }
    }
}

#pragma mark - getters
- (NSString *)baseURLString {
    return [[settingCentre thread_content_host] stringByReplacingOccurrencesOfString:kParentID withString:self.parentID];
}

- (NSMutableArray *)threads {
    // Should always include the parent thread.
    if (!_threads) {
        _threads = [NSMutableArray new];
        if (self.parentThread) {
            [_threads addObject:self.parentThread];
        }
    }
    return _threads;
}

#pragma mark - czzMassiveThreadDownloaderDelegate

- (void)threadDownloaderCompleted:(czzThreadDownloader *)downloader success:(BOOL)success downloadedThreads:(NSArray *)threads error:(NSError *)error {
    NSInteger previousThreadCount = self.threads.count;
    if (success) {
        self.lastBatchOfThreads = threads;
        // Remove the parent thread for easier calculation.
        if (self.parentThread) {
            [self.threads removeObject:self.parentThread];
        }
        if (downloader.parentThread.ID > 0)
            self.parentThread = downloader.parentThread;
        // If the page has not been increased by [self loadMoreThreads:] method, then we will need to sub-array the current threads.
        // Sub-array everything up to the last page end point.
        if (!self.pageNumberChanged) {
            NSInteger lastPageThreadCount = (downloader.pageNumber - 1) * settingCentre.response_per_page;
            NSRange previousRange = NSMakeRange(0, lastPageThreadCount);
            self.threads = [[self.threads subarrayWithRange:previousRange] mutableCopy];
        }
        [self.threads addObjectsFromArray:self.lastBatchOfThreads];
        // Add back the parent thread.
        if (self.parentThread) {
            [self.threads insertObject:self.parentThread atIndex:0];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        // If the downloader is a massive thread downloader, don't inform delegate about thread download completed event, because there could be more such events.
        if ([downloader isKindOfClass:[czzMassiveThreadDownloader class]]) {
            // For massive downloader, if the result is success but no new thread has been added, consider this as a failure.
            if (success && previousThreadCount == self.threads.count) {
                DLog(@"Massive downloader provided no new content, stopping...");
                [self stopAllOperation];
                if ([self.delegate respondsToSelector:@selector(homeViewManager:threadContentProcessed:newThreads:allThreads:)]) {
                    [self.delegate homeViewManager:self
                            threadContentProcessed:false
                                        newThreads:self.lastBatchOfThreads
                                        allThreads:self.threads];
                }
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(homeViewManager:threadContentProcessed:newThreads:allThreads:)]) {
                [self.delegate homeViewManager:self
                        threadContentProcessed:success
                                    newThreads:self.lastBatchOfThreads
                                    allThreads:self.threads];
            }
        }
    });
}

- (void)massiveDownloaderUpdated:(czzMassiveThreadDownloader *)downloader {
    // At the moment, the downloading is not finished yet.
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(viewManagerContinousDownloadUpdated:)]) {
            [self.delegate viewManagerContinousDownloadUpdated:self];
        }
    });
}

- (void)massiveDownloader:(czzMassiveThreadDownloader *)downloader success:(BOOL)success downloadedThreads:(NSArray *)threads errors:(NSArray *)errors {
    DLog(@"");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(viewManager:continousDownloadCompleted:)]) {
            [self.delegate viewManager:self continousDownloadCompleted:success];
        }
    });
}

#pragma mark - content managements.
- (void)reset {
    self.totalPages = self.pageNumber = 1;
    self.threads = self.cachedThreads = nil;
    self.pageNumberChanged = NO;
}

-(void)removeAll {
    self.pageNumber = 1;
    // Clear all.
    self.lastBatchOfThreads = self.threads = nil;
}

- (void)refresh {
    [self reset];
    [super refresh];
}

- (void)loadAll {
    DLog(@"");
    [self stopAllOperation];
    self.massiveDownloader = [[czzMassiveThreadDownloader alloc] initWithForum:self.downloader.parentForum
                                                                     andThread:self.downloader.parentThread];
    self.massiveDownloader.delegate = self;
    self.massiveDownloader.pageNumber = self.pageNumber + 1; // Start from the next page.
    [self.massiveDownloader start];
}

- (void)stopAllOperation {
    DLog(@"Should stop all downloading operation.");
    if (self.massiveDownloader) {
        [self.massiveDownloader stop];
    }
    if (self.downloader) {
        [self.downloader stop];
    }
}

- (void)loadMoreThreads {
    // Determine whether or nor I should +1 to the given pageNumber.
    // If the downloaded response can be % by response_per_page, that means all is OK.
    NSInteger remainder = (self.threads.count - 1) % settingCentre.response_per_page;
    if (remainder == 0) {
        [self loadMoreThreads:self.pageNumber + 1];
    } else {
        [self loadMoreThreads:self.pageNumber];
    }
}

- (void)loadMoreThreads:(NSInteger)pageNumber {
    NSInteger currentPage = self.pageNumber;
    [super loadMoreThreads:pageNumber];
    // If the updated page number is different than the old page number, set self.pageIncreased to true.
    self.pageNumberChanged = self.pageNumber != currentPage;
}

#pragma mark - NSCoding
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.parentThread forKey:@"parentThread"];
    [aCoder encodeInteger:self.pageNumber forKey:@"pageNumber"];
    [aCoder encodeInteger:self.totalPages forKey:@"totalPages"];
    [aCoder encodeObject:self.threads forKey:@"threads"];
    [aCoder encodeObject:self.lastBatchOfThreads forKey:@"lastBatchOfThreads"];
    [aCoder encodeObject:[NSValue valueWithCGPoint:self.currentOffSet] forKey:@"currentOffSet"];
    [aCoder encodeObject:self.forum forKey:@"forum"];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    czzThreadViewManager *threadViewManager = [czzThreadViewManager new];
    [[NSNotificationCenter defaultCenter] removeObserver:threadViewManager];
    @try {
        //create a temporary threadlist object
        threadViewManager.parentThread = [aDecoder decodeObjectForKey:@"parentThread"];
        threadViewManager.pageNumber = [aDecoder decodeIntegerForKey:@"pageNumber"];
        threadViewManager.totalPages = [aDecoder decodeIntegerForKey:@"totalPages"];
        threadViewManager.threads = [aDecoder decodeObjectForKey:@"threads"];
        threadViewManager.lastBatchOfThreads = [aDecoder decodeObjectForKey:@"lastBatchOfThreads"];
        threadViewManager.currentOffSet = [[aDecoder decodeObjectForKey:@"currentOffSet"] CGPointValue];
        threadViewManager.forum = [aDecoder decodeObjectForKey:@"forum"];
        return threadViewManager;
        
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
    }
    return nil;
}

// Override to support return self
+ (instancetype)sharedManager
{
    [NSException raise:@"NOT SUPPORTED" format:@"This class should not be a singleton: %@", NSStringFromClass([self class])];
    return nil;
}

#pragma mark - Getter

- (czzThreadDownloader *)downloader {
    if (!_downloader) {
        _downloader = [[czzThreadDownloader alloc] initWithForum:self.forum andThread:self.parentThread];
    }
    _downloader.parentForum = self.forum;
    _downloader.parentThread = self.parentThread;
    _downloader.delegate = self;
    return _downloader;
}

// Override isDownloading, this class need to consider the massive downloader as well.
- (BOOL)isDownloading {
    BOOL massiveDownloading = self.massiveDownloader.isDownloading;
    BOOL normalDownloading = super.isDownloading;
    return normalDownloading || massiveDownloading;
}

- (BOOL)isMassiveDownloading {
    return self.massiveDownloader.isDownloading;
}

@end
