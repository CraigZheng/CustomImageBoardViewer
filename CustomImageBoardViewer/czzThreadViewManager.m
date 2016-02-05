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
#import "czzThreadDownloader.h"

@interface czzThreadViewManager()
@property (nonatomic, assign) NSUInteger cutOffIndex;
@end

@implementation czzThreadViewManager
@synthesize forum = _forum;
@synthesize downloader = _downloader;
@synthesize threads = _threads;
@dynamic delegate;

#pragma mark - life cycle.
-(instancetype)initWithParentThread:(czzThread *)thread andForum:(czzForum *)forum{
    self = [czzThreadViewManager new];
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
    @try {
        NSString *cacheFile = [[czzAppDelegate threadCacheFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld%@", (long)self.parentThread.ID, SUB_THREAD_LIST_CACHE_FILE]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
            czzThreadViewManager *tempThreadList = [self restoreWithFile:cacheFile];
            //copy data
            if (tempThreadList && [tempThreadList isKindOfClass:[czzThreadViewManager class]])
            {
                self.parentThread = tempThreadList.parentThread;
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
        DDLogDebug(@"%@", exception);
    }
}

-(NSString*)saveCurrentState {
    NSString *cachePath = [[czzAppDelegate threadCacheFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld%@", (long)self.parentThread.ID, SUB_THREAD_LIST_CACHE_FILE]];
    if ([NSKeyedArchiver archiveRootObject:self toFile:cachePath]) {
        return cachePath;
    } else {
        DDLogDebug(@"save state failed");
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
        return nil;
    }
}

#pragma mark - Delegate actions
- (void)showContentWithThread:(czzThread *)thread {
    if (thread && [self.delegate respondsToSelector:@selector(threadViewManager:wantsToShowContentForThread:)]) {
        [self.delegate threadViewManager:self wantsToShowContentForThread:thread];
    } else {
        DDLogDebug(@"Thread or delegate nil: %s", __PRETTY_FUNCTION__);
    }
}

#pragma mark - setters
-(void)setParentThread:(czzThread *)thread {
    _parentThread = thread;
    self.parentID = [NSString stringWithFormat:@"%ld", (long)self.parentThread.ID];
    
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

#pragma mark - czzThreadDownloaderDelegate

- (void)threadDownloaderCompleted:(czzThreadDownloader *)downloader success:(BOOL)success downloadedThreads:(NSArray *)threads error:(NSError *)error {
    self.isDownloading = NO;
    if (success) {
        self.lastBatchOfThreads = threads;
        if (downloader.parentThread)
            self.parentThread = downloader.parentThread;
        NSArray *processedNewThread;
        if (self.threads.count > 0) {
            NSInteger lastChunkIndex = self.threads.count - self.lastBatchOfThreads.count;
            if (lastChunkIndex < 1)
                lastChunkIndex = 1;
            self.cutOffIndex = lastChunkIndex;
            NSInteger lastChunkLength = self.threads.count - lastChunkIndex;
            NSRange lastChunkRange = NSMakeRange(lastChunkIndex, lastChunkLength);
            NSArray *lastChunkOfThread = [self.threads subarrayWithRange:lastChunkRange];
            NSMutableOrderedSet *oldThreadSet = [NSMutableOrderedSet orderedSetWithArray:lastChunkOfThread];
            [oldThreadSet addObjectsFromArray:threads];
            [self.threads removeObjectsInRange:lastChunkRange];
            processedNewThread = oldThreadSet.array;
        } else {
            self.cutOffIndex = 0;
            NSMutableArray *threadsWithParent = [NSMutableArray new];
            [threadsWithParent addObject:self.parentThread];
            [threadsWithParent addObjectsFromArray:threads];
            processedNewThread = threadsWithParent;
        }
        self.lastBatchOfThreads = processedNewThread;
        [self.threads addObjectsFromArray:self.lastBatchOfThreads];
        //replace parent thread
        if (self.threads.count >= 1)
        {
            [self.threads replaceObjectAtIndex:0 withObject:self.parentThread];
        } else {
            [self.threads insertObject:self.parentThread atIndex:0];
        }
    }
    //calculate current number and total page number
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(homeViewManager:threadContentProcessed:newThreads:allThreads:)]) {
            [self.delegate homeViewManager:self threadContentProcessed:success newThreads:self.lastBatchOfThreads allThreads:self.threads];
        }
    });

}

#pragma mark - content managements.
- (void)reset {
    self.totalPages = self.pageNumber = 1;
    self.threads = self.cachedThreads = nil;
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

#pragma mark - highlight thread selected
-(void)HighlightThreadSelected:(czzThread *)selectedThread {
    if (selectedThread) {
        if ([self.selectedUserToHighlight isEqual:selectedThread.UID]) {
            self.selectedUserToHighlight = nil;
        }
        else
            self.selectedUserToHighlight = selectedThread.UID;
        [self.delegate homeViewManagerWantsToReload:self];
    }
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

- (NSMutableDictionary *)referenceIndexDictionary {
    if (!_referenceIndexDictionary) {
        _referenceIndexDictionary = [NSMutableDictionary new];
    }
    return _referenceIndexDictionary;
}

@end
