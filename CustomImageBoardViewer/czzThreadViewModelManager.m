//
//  czzSubThreadList.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//
#define settingCentre [czzSettingsCentre sharedInstance]

#import "czzThreadViewModelManager.h"
#import "czzHistoryManager.h"

@interface czzThreadViewModelManager()
@property NSUInteger cutOffIndex;
@end

@implementation czzThreadViewModelManager
@synthesize forum = _forum;

-(instancetype)initWithParentThread:(czzThread *)thread andForum:(czzForum *)forum{
    self = [czzThreadViewModelManager new];
    if (self) {
        // Record history
        self.parentThread = thread;
        if (self.parentThread)
            [historyManager recordThread:self.parentThread];

        self.forum = forum;
        // Give it a default forum
        if (!self.forum) {
            self.forum = [czzForum new];
        }
        self.parentThread = thread;
        self.parentID = [NSString stringWithFormat:@"%ld", (long) self.parentThread.ID];
        self.threadContentListDataProcessor = [czzJSONProcessor new];
        self.threadContentListDataProcessor.delegate = self;
        [self reset];
    }
    
    return self;
}

-(instancetype)restoreWithFile:(NSString *)filePath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        czzThreadViewModelManager *tempThreadList = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        //copy data
        if (tempThreadList && [tempThreadList isKindOfClass:[czzThreadViewModelManager class]])
        {
            return tempThreadList;
        }
    }
    return nil;
}

#pragma mark - state perserving/restoring
-(void)restorePreviousState {
    @try {
        NSString *cacheFile = [[czzAppDelegate threadCacheFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld%@", (long)self.parentThread.ID, SUB_THREAD_LIST_CACHE_FILE]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
            czzThreadViewModelManager *tempThreadList = [self restoreWithFile:cacheFile];
            //copy data
            if (tempThreadList && [tempThreadList isKindOfClass:[czzThreadViewModelManager class]])
            {
                self.parentThread = tempThreadList.parentThread;
                self.pageNumber = tempThreadList.pageNumber;
                self.totalPages = tempThreadList.totalPages;
                self.threads = tempThreadList.threads;
                self.verticalHeights = tempThreadList.self.verticalHeights;
                self.horizontalHeights = tempThreadList.self.horizontalHeights;
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
        DLog(@"%@", exception);
    }
}

-(NSString*)saveCurrentState {
    NSString *cachePath = [[czzAppDelegate threadCacheFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld%@", (long)self.parentThread.ID, SUB_THREAD_LIST_CACHE_FILE]];
    if ([NSKeyedArchiver archiveRootObject:self toFile:cachePath]) {
        return cachePath;
    } else {
        DLog(@"save state failed");
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
        return nil;
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

#pragma mark - czzXMLDownloaderDelegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)receivedData {
    self.isDownloading = NO;
    if (successed) {
        [self.threadContentListDataProcessor processSubThreadFromData:receivedData forForum:self.forum];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(viewModelManager:downloadSuccessful:)]) {
            [self.delegate viewModelManager:self downloadSuccessful:successed];
        }
    });
}

#pragma mark - czzJsonProcesserDelegate
-(void)subThreadProcessedForThread:(czzJSONProcessor *)processor :(czzThread *)forThread :(NSArray *)newThread :(BOOL)success {
    self.isProcessing = NO;
    if (success) {
        self.lastBatchOfThreads = newThread;
        self.parentThread = forThread ? forThread : self.parentThread;
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
            [oldThreadSet addObjectsFromArray:newThread];
            [self.threads removeObjectsInRange:lastChunkRange];
            processedNewThread = oldThreadSet.array;
        } else {
            self.cutOffIndex = 0;
            NSMutableArray *threadsWithParent = [NSMutableArray new];
            [threadsWithParent addObject:self.parentThread];
            [threadsWithParent addObjectsFromArray:newThread];
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
        [self calculateHeightsForThreads:self.lastBatchOfThreads cutOffFromIndex:self.cutOffIndex];
    }
    // Download images for the new batch of threads
    [self downloadThumbnailsForThreads:newThread];
    //calculate current number and total page number
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(viewModelManager:processedSubThreadData:newThreads:allThreads:)]) {
            [self.delegate viewModelManager:self processedSubThreadData:success newThreads:self.lastBatchOfThreads allThreads:self.threads];
        }
    });
}

float RoundTo(float number, float to)
{
    if (number >= 0) {
        return to * floorf(number / to + 1.);
    }
    else {
        return to * ceilf(number / to - 0.5f);
    }
}


/*
 calculate heights for both horizontal and vertical of the parent view controller
 */
-(void)calculateHeightsForThreads:(NSArray*)newThreads cutOffFromIndex:(NSInteger)cutOffIndex{
    @try {
        // Remove duplicate height objects, then calculate the newThreads
        [self.verticalHeights removeObjectsInRange:NSMakeRange(cutOffIndex, self.verticalHeights.count - cutOffIndex)];
        [self.horizontalHeights removeObjectsInRange:NSMakeRange(cutOffIndex, self.horizontalHeights.count - cutOffIndex)];
        [super calculateHeightsForThreads:newThreads];

    }
    @catch (NSException *exception) {
        // If error, remove all height objects, and calculate all from the beginning
        DLog(@"%@", exception);
        [self.verticalHeights removeAllObjects];
        [self.horizontalHeights removeAllObjects];
        [super calculateHeightsForThreads:self.threads];
    }
}

- (void)reset {
    self.totalPages = self.pageNumber = 1;
    self.threads = self.horizontalHeights = self.verticalHeights = nil;
    self.cachedThreads = self.cachedHorizontalHeights = self.cachedVerticalHeights = nil;
}

- (void)refresh {
    [self reset];
    [super refresh];
}

#pragma mark - NSCoding
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.parentThread forKey:@"parentThread"];
    [aCoder encodeInteger:self.pageNumber forKey:@"pageNumber"];
    [aCoder encodeInteger:self.totalPages forKey:@"totalPages"];
    [aCoder encodeObject:self.threads forKey:@"threads"];
    [aCoder encodeObject:self.lastBatchOfThreads forKey:@"lastBatchOfThreads"];
    [aCoder encodeObject:self.horizontalHeights forKey:@"self.horizontalHeights"];
    [aCoder encodeObject:self.verticalHeights forKey:@"self.verticalHeights"];
    [aCoder encodeObject:[NSValue valueWithCGPoint:self.currentOffSet] forKey:@"currentOffSet"];
    [aCoder encodeObject:self.forum forKey:@"forum"];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    czzThreadViewModelManager *newThreadList = [czzThreadViewModelManager new];
    [[NSNotificationCenter defaultCenter] removeObserver:newThreadList];
    @try {
        //create a temporary threadlist object
        newThreadList.parentThread = [aDecoder decodeObjectForKey:@"parentThread"];
        newThreadList.pageNumber = [aDecoder decodeIntegerForKey:@"pageNumber"];
        newThreadList.totalPages = [aDecoder decodeIntegerForKey:@"totalPages"];
        newThreadList.threads = [aDecoder decodeObjectForKey:@"threads"];
        newThreadList.lastBatchOfThreads = [aDecoder decodeObjectForKey:@"lastBatchOfThreads"];
        newThreadList.self.horizontalHeights = [aDecoder decodeObjectForKey:@"self.horizontalHeights"];
        newThreadList.self.verticalHeights = [aDecoder decodeObjectForKey:@"self.verticalHeights"];
        newThreadList.currentOffSet = [[aDecoder decodeObjectForKey:@"currentOffSet"] CGPointValue];
        newThreadList.forum = [aDecoder decodeObjectForKey:@"forum"];
        return newThreadList;
        
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
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

@end