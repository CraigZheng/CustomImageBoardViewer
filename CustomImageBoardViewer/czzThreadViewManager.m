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
#import "czzFavouriteManager.h"
#import "NSArray+Splitting.h"

#import "CustomImageBoardViewer-Swift.h"

typedef enum : NSUInteger {
    ViewManagerLoadingModeNormal,
    ViewManagerLoadingModeJumpping
} ViewManagerLoadingMode;

@interface czzThreadViewManager() <czzMassiveThreadDownloaderDelegate>
@property (nonatomic, assign) BOOL pageNumberChanged;
@property (nonatomic, assign) NSInteger previousPageNumber;
@property (nonatomic, strong) czzMassiveThreadDownloader *massiveDownloader;
@property (nonatomic, assign) ViewManagerLoadingMode loadingMode;
@property (nonatomic, readonly) NSInteger totalPages;
@end

@implementation czzThreadViewManager
@synthesize forum = _forum;
@synthesize downloader = _downloader;
@synthesize threads = _threads;
@dynamic delegate, totalPages;

#pragma mark - life cycle.
-(instancetype)initWithParentThread:(czzThread *)thread andForum:(czzForum *)forum{
    self = [self init];
    if (self) {
        self.parentThread = thread;
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
    // Restore previous page number.
    self.pageNumber = [[NSUserDefaults standardUserDefaults] integerForKey:self.pageNumberKey] ?: 1;
}

-(NSString*)saveCurrentState {
    [[NSUserDefaults standardUserDefaults] setInteger:self.threads.lastObject.pageNumber ?: 1 forKey:self.pageNumberKey];
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
        [historyManager recordThread:self.parentThread];
        [czzFavouriteManager.sharedInstance updateFavourite:self.parentThread];
    }
}

#pragma mark - czzMassiveThreadDownloaderDelegate

- (void)threadDownloaderCompleted:(czzThreadDownloader *)downloader success:(BOOL)success downloadedThreads:(NSArray *)threads error:(NSError *)error {
    NSInteger previousThreadCount = self.threads.count;
    // Remove the parent thread for easier calculation.
    if (downloader.parentThread.ID > 0) {
        self.parentThread = downloader.parentThread;
        if (self.threads.firstObject.pageNumber == 0) {
            self.threads.firstObject.threads = @[self.parentThread];
        }
    }
    if (success) {
        // Remove any threads with ignored IDs.
        for (NSNumber *ignoredID in settingCentre.ignoredThreadIDs) {
            NSArray *threadsWithIgnoredID = [threads filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"ID == %ld", (long) ignoredID.longValue]];
            if (threadsWithIgnoredID.count) {
                NSMutableArray *mutableThreads = threads.mutableCopy;
                [mutableThreads removeObjectsInArray:threadsWithIgnoredID];
                threads = mutableThreads;
            }
        }
        ContentPage *page = [[ContentPage alloc] init];
        page.threads = threads;
        page.pageNumber = downloader.pageNumber;
        page.forum = self.forum;
        if (self.threads.lastObject.pageNumber == downloader.pageNumber) {
            [self.threads removeLastObject];
        }
        if (self.pageNumber < downloader.pageNumber) {
            [self.threads addObject:page];
        } else {
            [self.threads insertObject:page atIndex:0];
        }
        self.lastBatchOfThreads = threads;
        self.pageNumber = downloader.pageNumber;
    }
    // Sort by page number.
    [self.threads sortUsingComparator:^NSComparisonResult(ContentPage * _Nonnull page1, ContentPage * _Nonnull page2) {
        return page1.pageNumber < page2.pageNumber ? NSOrderedAscending : NSOrderedDescending;
    }];
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
    self.pageNumber = 1;
    self.pageNumberChanged = NO;
    self.loadingMode = ViewManagerLoadingModeNormal;
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

- (void)loadPreviousPage {
    if (self.threads.count >= 2 && self.threads[1].pageNumber > 1) {
        [self loadMoreThreads:self.threads[1].pageNumber - 1];
    } else {
        [self refresh];
    }
}

- (void)loadAll {
    DLog(@"");
    [self stopAllOperation];
    self.massiveDownloader = [[czzMassiveThreadDownloader alloc] initWithForum:self.downloader.parentForum
                                                                     andThread:self.downloader.parentThread];
    self.massiveDownloader.delegate = self;
    self.massiveDownloader.pageNumber = self.threads.lastObject.pageNumber + 1; // Start from the next page.
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
    if (self.threads.lastObject.count >= settingCentre.response_per_page) {
        [self loadMoreThreads:self.threads.lastObject.pageNumber + 1];
    } else {
        [self loadMoreThreads:self.threads.lastObject.pageNumber];
    }
}

- (void)loadMoreThreads:(NSInteger)pageNumber {
    self.previousPageNumber = self.pageNumber;
    [super loadMoreThreads:pageNumber];
    // If the updated page number is different than the old page number, set self.pageIncreased to true.
    self.pageNumberChanged = self.pageNumber != self.previousPageNumber;
}

- (void)jumpToPage:(NSInteger)page {
    [self stopAllOperation];
    [self removeAll];
    self.threads = nil;
    self.loadingMode = ViewManagerLoadingModeJumpping;
    [self loadMoreThreads:page];
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

#pragma mark - Getters

- (NSMutableArray<ContentPage *> *)threads {
    if (!_threads) {
        _threads = [[NSMutableArray alloc] init];
        // Parent thread would be hosted in its own section.
        ContentPage *page = [[ContentPage alloc] init];
        page.threads = @[self.parentThread];
        page.pageNumber = 0;
        page.forum = self.forum;
        [_threads addObject:page];
    }
    return _threads;
}

- (NSInteger)totalPages {
    CGFloat totalPages = (CGFloat)self.parentThread.responseCount / (CGFloat)settingCentre.response_per_page;
    return ceilf(totalPages);
}

- (NSString *)pageNumberKey {
    return [[settingCentre activeHost] stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)self.parentThread.ID]];
}

- (NSString *)baseURLString {
    return [[settingCentre thread_content_host] stringByReplacingOccurrencesOfString:kParentID withString:self.parentID];
}

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
