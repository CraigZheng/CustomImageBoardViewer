//
//  czzThreadList.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzHomeViewManager.h"
#import "czzImageCacheManager.h"
#import "czzImageDownloaderManager.h"
#import "czzMarkerManager.h"
#import "czzNavigationController.h"
#import <Google/Analytics.h>

@interface czzHomeViewManager ()
@property (nonatomic, readonly) NSString *cacheFile;
@property (nonatomic, assign) BOOL isDownloading;
@end

@implementation czzHomeViewManager

-(instancetype)init {
    self = [super init];
    if (self) {
        self.pageNumber = self.totalPages = 1;
    }
    return self;
}

#pragma mark - state perserving/restoring
-(NSString*)saveCurrentState {
    NSString *cachePath = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:self.cacheFile];
    if ([NSKeyedArchiver archiveRootObject:self toFile:cachePath]) {
        DDLogDebug(@"save state successed");
        return cachePath;
    } else {
        DDLogDebug(@"save state failed");
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
        return nil;
    }
}

-(void)restorePreviousState {
    @try {
        NSString *cacheFile = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:self.cacheFile];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
            NSData *cacheData = [NSData dataWithContentsOfFile:cacheFile];
            // Always delete the cache file after reading it to ensure safety.
            [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
            czzHomeViewManager *tempThreadList = [NSKeyedUnarchiver unarchiveObjectWithData:cacheData];
            //copy data
            if (tempThreadList && [tempThreadList isKindOfClass:[czzHomeViewManager class]])
            {
                self.forum = tempThreadList.forum;
                self.pageNumber = tempThreadList.pageNumber;
                self.totalPages = tempThreadList.totalPages;
                self.threads = tempThreadList.threads;
                self.currentOffSet = tempThreadList.currentOffSet;
                self.lastBatchOfThreads = tempThreadList.lastBatchOfThreads;
                self.shouldHideImageForThisForum = tempThreadList.shouldHideImageForThisForum;
                self.displayedThread = tempThreadList.displayedThread;
            }
        }
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
    }
}

#pragma mark - reload/refresh actions
- (void)reloadData {
    if ([self.delegate respondsToSelector:@selector(homeViewManagerWantsToReload:)]) {
        [self.delegate homeViewManagerWantsToReload:self];
    }
}

-(void)refresh {
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Refresh"
                                                                                        action:@"Refresh Forum"
                                                                                         label:self.forum.name
                                                                                         value:@1] build]];
    [self removeAll];
    [self loadMoreThreads:self.pageNumber];
}

-(void)loadMoreThreads {
    [self loadMoreThreads:self.pageNumber + 1];
}

-(void)loadMoreThreads:(NSInteger)pageNumber {
    if (!self.forum) {
        DDLogDebug(@"Forum not set, cannot load more.");
        return;
    }
#ifdef UNITTEST
    NSData *mockData = [[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"threadList" ofType:@"json"]]];
    [self downloadOf:nil successed:YES result:mockData];
    return;
#endif
    if (self.downloader.isDownloading)
        [self.downloader stop];
    if (pageNumber > self.totalPages)
        pageNumber = self.totalPages;
    // Construct and start downloading for forum with page number,
    self.downloader.pageNumber = pageNumber;
    [self.downloader start];
}

-(void)removeAll {
    self.pageNumber = 1;
    // Keep old threads in the cache
    self.cachedThreads = self.threads;
    
    // Clear all.
    self.lastBatchOfThreads = self.threads = nil;
}

- (void)scrollToContentOffset:(CGPoint)offset {
    if ([self.delegate respondsToSelector:@selector(homeViewManager:wantsToScrollToContentOffset:)]) {
        [self.delegate homeViewManager:self wantsToScrollToContentOffset:offset];
    }
}

#pragma mark - Marking/blocking

- (void)highlightUID:(NSString *)UID {
    [[czzMarkerManager sharedInstance] prepareToHighlightUID:UID];
    [NavigationManager.delegate performSegueWithIdentifier:@"showAddMarker"
                                                    sender:nil];
}

- (void)blockUID:(NSString *)UID {
    if ([[czzMarkerManager sharedInstance] isUIDBlocked:UID]) {
        [[czzMarkerManager sharedInstance] unBlockUID:UID];
    } else {
        [[czzMarkerManager sharedInstance] blockUID:UID];
    }
    [self reloadData];
}

#pragma mark - Delegate actions
- (void)showContentWithThread:(czzThread *)thread {
    if (thread && [self.delegate respondsToSelector:@selector(homeViewManager:wantsToShowContentForThread:)]) {
        [self.delegate homeViewManager:self wantsToShowContentForThread:thread];
    } else {
        DDLogDebug(@"Thread or delegate nil: %s", __PRETTY_FUNCTION__);
    }
}

#pragma mark - czzThreadDownloaderDelegate
- (void)threadDownloaderStateChanged:(czzThreadDownloader *)downloader {
    self.isDownloading = downloader.isDownloading;
    if ([self.delegate respondsToSelector:@selector(viewManagerDownloadStateChanged:)]) {
        [self.delegate viewManagerDownloadStateChanged:self];
    }
}

- (void)threadDownloaderDownloadUpdated:(czzThreadDownloader *)downloader progress:(CGFloat)progress {
    if ([self.delegate respondsToSelector:@selector(homeViewManager:downloadProgressUpdated:)])
        [self.delegate homeViewManager:self downloadProgressUpdated:progress];
}

- (void)threadDownloaderCompleted:(czzThreadDownloader *)downloader success:(BOOL)success downloadedThreads:(NSArray *)threads error:(NSError *)error {
    if (success){
        self.cachedThreads = nil;
        if (self.shouldHideImageForThisForum)
        {
            for (czzThread *thread in threads) {
                thread.thImgSrc = nil;
            }
        }
        self.lastBatchOfThreads = threads;
        // Add to total threads.
        [self.threads addObjectsFromArray:threads];
    }
    if ([self.delegate respondsToSelector:@selector(homeViewManager:threadListProcessed:newThreads:allThreads:)]) {
        [self.delegate homeViewManager:self threadListProcessed:success newThreads:self.lastBatchOfThreads allThreads:self.threads];
    }
    if ([self.delegate respondsToSelector:@selector(homeViewManager:downloadSuccessful:)]) {
        [self.delegate homeViewManager:self downloadSuccessful:success];
    }
}

- (void)pageNumberUpdated:(NSInteger)currentPage allPage:(NSInteger)allPage {
    DDLogDebug(@"%s : %ld/%ld", __PRETTY_FUNCTION__, (long)currentPage, (long)allPage);
    self.pageNumber = currentPage;
    self.totalPages = allPage;
}

#pragma mark - Setters
-(void)setForum:(czzForum *)forum {
    _forum = forum;
}

#pragma mark - Getters

- (czzThreadDownloader *)downloader {
    if (!_downloader) {
        _downloader =  [[czzThreadDownloader alloc] initWithForum:self.forum];
    }
    _downloader.delegate = self;
    _downloader.parentForum = self.forum;
    return _downloader;
}

/**
 Total page should never be smaller than 1.
 */
- (NSInteger)totalPages {
    if (_totalPages <= 1) {
        _totalPages = 1;
    }
    return _totalPages;
}

/**
 Shhould never be smaller than 1.
 */
- (NSInteger)pageNumber {
    if (_pageNumber <= 1) {
        _pageNumber = 1;
    }
    return _pageNumber;
}

- (NSString *)cacheFile {
    return [NSString stringWithFormat:@"%@-%@", [UIApplication bundleVersion], DEFAULT_THREAD_LIST_CACHE_FILE];
}

- (NSMutableArray *)threads {
    if (!_threads) {
        _threads = [NSMutableArray new];
    }
    if (!_threads.count && self.cachedThreads.count) {
        return self.cachedThreads;
    }
    return _threads;
}

#pragma mark - NSCoding
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:self.shouldHideImageForThisForum forKey:@"shouldHideImageForThisForum"];
    [aCoder encodeObject:self.forum forKey:@"forum"];
    [aCoder encodeInteger:self.pageNumber forKey:@"pageNumber"];
    [aCoder encodeInteger:self.totalPages forKey:@"totalPages"];
    [aCoder encodeObject:self.threads forKey:@"threads"];
    [aCoder encodeObject:self.lastBatchOfThreads forKey:@"lastBatchOfThreads"];
    //parent view controller can not be encoded
    //delegate can not be encoded
    //isDownloading and isProcessing should not be encoded
    [aCoder encodeObject:[NSValue valueWithCGPoint:self.currentOffSet] forKey:@"currentOffSet"];
    [aCoder encodeObject:self.displayedThread forKey:@"displayedThread"];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    czzHomeViewManager *homeViewManager = [czzHomeViewManager new];
    @try {
        //create a temporary threadlist object
        homeViewManager.shouldHideImageForThisForum = [aDecoder decodeBoolForKey:@"shouldHideImageForThisForum"];
        homeViewManager.forum = [aDecoder decodeObjectForKey:@"forum"];
        homeViewManager.pageNumber = [aDecoder decodeIntegerForKey:@"pageNumber"];
        homeViewManager.totalPages = [aDecoder decodeIntegerForKey:@"totalPages"];
        homeViewManager.threads = [aDecoder decodeObjectForKey:@"threads"];
        homeViewManager.lastBatchOfThreads = [aDecoder decodeObjectForKey:@"lastBatchOfThreads"];
        homeViewManager.currentOffSet = [[aDecoder decodeObjectForKey:@"currentOffSet"] CGPointValue];
        homeViewManager.displayedThread = [aDecoder decodeObjectForKey:@"displayedThread"];
        return homeViewManager;

    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
    }
    return nil;
}

__strong static id _sharedObject = nil;
+ (instancetype)sharedManager
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        if (!_sharedObject) {
            _sharedObject = [[self alloc] init];
        }
    });
    
    // returns the same object each time
    return _sharedObject;
}

+ (void)setSharedManager:(czzHomeViewManager *)manager {
    _sharedObject = manager;
}

@end
