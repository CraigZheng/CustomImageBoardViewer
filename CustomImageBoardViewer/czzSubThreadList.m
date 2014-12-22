//
//  czzSubThreadList.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//
#define settingCentre [czzSettingsCentre sharedInstance]

#import "czzSubThreadList.h"

@interface czzSubThreadList()
@property NSUInteger cutOffIndex;
@end

@implementation czzSubThreadList
@synthesize totalPages;
@synthesize parentID;
@synthesize parentThread;
@synthesize baseURLString;
@synthesize delegate;
@synthesize xmlDownloader;
@synthesize threadListProcessor;
@synthesize subThreadProcessor;
@synthesize pageNumber;
@synthesize isDownloading, isProcessing;
@synthesize parentViewController;
@synthesize threads;
@synthesize verticalHeights, horizontalHeights;
@synthesize lastBatchOfThreads;
@synthesize cutOffIndex;
@synthesize currentOffSet;
@synthesize restoredFromCache;

-(instancetype)initWithParentThread:(czzThread *)thread {
    self = [super init];
    if (self) {
        parentThread = thread;
        parentID = [NSString stringWithFormat:@"%ld", (long) parentThread.ID];
        subThreadProcessor = [czzJSONProcessor new];
        subThreadProcessor.delegate = self;
        baseURLString = [[settingCentre thread_content_host] stringByAppendingPathComponent:parentID];
        totalPages = pageNumber = 1;

        threads = [NSMutableArray new];
        verticalHeights = [NSMutableArray new];
        horizontalHeights = [NSMutableArray new];
        
    }
    
    return self;
}

-(void)restorePreviousState {
    @try {
        NSString *cacheFile = [[czzAppDelegate threadCacheFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld%@", (long)parentThread.ID, SUB_THREAD_LIST_CACHE_FILE]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
            czzSubThreadList *tempThreadList = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile];
            //always delete the cache file after reading it to ensure safety
            [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
            //copy data
            if (tempThreadList && [tempThreadList isKindOfClass:[czzSubThreadList class]])
            {
                self.parentThread = tempThreadList.parentThread;
                self.pageNumber = tempThreadList.pageNumber;
                self.totalPages = tempThreadList.totalPages;
                self.threads = tempThreadList.threads;
                self.verticalHeights = tempThreadList.verticalHeights;
                self.horizontalHeights = tempThreadList.horizontalHeights;
                self.baseURLString = tempThreadList.baseURLString;
                self.currentOffSet = tempThreadList.currentOffSet;
                self.lastBatchOfThreads = tempThreadList.lastBatchOfThreads;
                self.shouldHideImageForThisForum = tempThreadList.shouldHideImageForThisForum;
                restoredFromCache = YES;
                return;
            }
        }
        restoredFromCache = NO;
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
}

-(void)entersBackground {
    DLog(@"%@", NSStringFromSelector(_cmd));
    [self saveCurrentState];
}

-(void)saveCurrentState {
    NSString *cachePath = [[czzAppDelegate threadCacheFolder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld%@", (long)parentThread.ID, SUB_THREAD_LIST_CACHE_FILE]];
    if ([NSKeyedArchiver archiveRootObject:self toFile:cachePath]) {
    } else {
        DLog(@"save state failed");
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
    }
}

-(void)refresh {
    [self removeAll];
    [self loadMoreThreads];
}

-(void)setParentViewController:(UIViewController *)viewCon {
    parentViewController = viewCon;
    //register an obverser while adding a parent view controller
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(entersBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

-(void)setParentThread:(czzThread *)thread {
    parentThread = thread;
    parentID = [NSString stringWithFormat:@"%ld", (long)parentThread.ID];
    baseURLString = [[settingCentre thread_content_host] stringByAppendingPathComponent:parentID];
}

-(void)removeAll {
    totalPages = pageNumber = 1;
    [threads removeAllObjects];
    lastBatchOfThreads = nil;
    [horizontalHeights removeAllObjects];
    [verticalHeights removeAllObjects];
}

-(void)loadMoreThreads {
    [self loadMoreThreads:pageNumber + 1];
}

-(void)loadMoreThreads:(NSInteger)pn {
#ifdef UNITTEST
    NSData *mockData = [[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"subThreadList" ofType:@"json"]]];
    [self downloadOf:nil successed:YES result:mockData];
    return;
#endif
    if (xmlDownloader)
        [xmlDownloader stop];
    pageNumber = pn;
    if (pageNumber >= totalPages)
        pageNumber = totalPages;
    NSString *targetURLStringWithPN = [baseURLString stringByAppendingString:[NSString stringWithFormat:@"?page=%ld", (long)pageNumber]];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
    isDownloading = YES;
    DLog(@"%@", targetURLStringWithPN);
    if (delegate && [delegate respondsToSelector:@selector(threadListBeginDownloading:)]) {
        [delegate threadListBeginDownloading:self];
    }
}

#pragma mark - czzXMLDownloaderDelegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData {
    isDownloading = NO;
    if (successed) {
        [subThreadProcessor processSubThreadFromData:xmlData];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (delegate && [delegate respondsToSelector:@selector(threadListDownloaded:wasSuccessful:)]) {
            [delegate threadListDownloaded:self wasSuccessful:successed];
        }
    });
}

#pragma mark - czzJsonProcesserDelegate
-(void)subThreadProcessedForThread:(czzJSONProcessor *)processor :(czzThread *)forThread :(NSArray *)newThread :(BOOL)success {
//    DLog(@"%@", NSStringFromSelector(_cmd));
    isProcessing = NO;
    if (success) {
        lastBatchOfThreads = newThread;
        parentThread = forThread ? forThread : parentThread;
        NSArray *processedNewThread;
        if (threads.count > 0) {
            NSInteger lastChunkIndex = threads.count - lastBatchOfThreads.count;
            if (lastChunkIndex < 1)
                lastChunkIndex = 1;
            cutOffIndex = lastChunkIndex;
            NSInteger lastChunkLength = threads.count - lastChunkIndex;
            NSRange lastChunkRange = NSMakeRange(lastChunkIndex, lastChunkLength);
            NSArray *lastChunkOfThread = [threads subarrayWithRange:lastChunkRange];
            NSMutableOrderedSet *oldThreadSet = [NSMutableOrderedSet orderedSetWithArray:lastChunkOfThread];
            [oldThreadSet addObjectsFromArray:newThread];
            [threads removeObjectsInRange:lastChunkRange];
            processedNewThread = oldThreadSet.array;
        } else {
            cutOffIndex = 0;
            NSMutableArray *threadsWithParent = [NSMutableArray new];
            [threadsWithParent addObject:parentThread];
            [threadsWithParent addObjectsFromArray:newThread];
            processedNewThread = threadsWithParent;
        }
        lastBatchOfThreads = processedNewThread;
        [threads addObjectsFromArray:lastBatchOfThreads];
        //replace parent thread
        if (threads.count >= 1)
        {
            [threads replaceObjectAtIndex:0 withObject:parentThread];
        }
        [self calculateHeightsForThreads:lastBatchOfThreads];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (delegate && [delegate respondsToSelector:@selector(subThreadProcessed:wasSuccessful:newThreads:allThreads:)]) {
            [delegate subThreadProcessed:self wasSuccessful:success newThreads:lastBatchOfThreads allThreads:threads];
        }
    });
}

-(void)pageNumberUpdated:(NSInteger)currentPage inAllPage:(NSInteger)allPage {
    pageNumber = currentPage;
    totalPages = allPage;
    DLog(@"current page: %ld, total pages:%ld",(long)pageNumber, (long)totalPages);
}

/*
 calculate heights for both horizontal and vertical of the parent view controller
 */
-(void)calculateHeightsForThreads:(NSArray*)newThreads {
    CGFloat shortWidth, longWidth;
    shortWidth = MIN([UIScreen mainScreen].applicationFrame.size.height, [UIScreen mainScreen].applicationFrame.size.width);
    longWidth = MAX([UIScreen mainScreen].applicationFrame.size.width, [UIScreen mainScreen].applicationFrame.size.height);
    dispatch_async(dispatch_get_main_queue(), ^{
//        NSDate *date = [NSDate new];
        if (verticalHeights.count > 0 && horizontalHeights.count > 0) {
            [verticalHeights removeObjectsInRange:NSMakeRange(cutOffIndex, verticalHeights.count - cutOffIndex)];
            [horizontalHeights removeObjectsInRange:NSMakeRange(cutOffIndex, verticalHeights.count - cutOffIndex)];
        }
        for (czzThread *thread in newThreads) {
            CGFloat shortHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:parentViewController.view forWidth:shortWidth hasImage:thread.imgSrc.length > 0];
            CGFloat longHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:parentViewController.view forWidth:longWidth hasImage:thread.imgSrc.length > 0];
            [verticalHeights addObject:[NSNumber numberWithFloat:shortHeight]];
            [horizontalHeights addObject:[NSNumber numberWithFloat:longHeight]];
        }
//        DLog(@"processing time: %.2f", [[NSDate new] timeIntervalSinceDate:date]);
//        DLog(@"size of heights array: %lu", verticalHeights.count);
    });
}

#pragma mark - NSCoding
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:parentThread forKey:@"parentThread"];
    [aCoder encodeInteger:pageNumber forKey:@"pageNumber"];
    [aCoder encodeInteger:totalPages forKey:@"totalPages"];
    [aCoder encodeObject:threads forKey:@"threads"];
    [aCoder encodeObject:lastBatchOfThreads forKey:@"lastBatchOfThreads"];
    [aCoder encodeObject:horizontalHeights forKey:@"horizontalHeights"];
    [aCoder encodeObject:verticalHeights forKey:@"verticalHeights"];
    [aCoder encodeObject:baseURLString forKey:@"baseURLString"];
    [aCoder encodeObject:[NSValue valueWithCGPoint:currentOffSet] forKey:@"currentOffSet"];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    czzSubThreadList *newThreadList = [czzSubThreadList new];
    [[NSNotificationCenter defaultCenter] removeObserver:newThreadList];
    @try {
        //create a temporary threadlist object
        newThreadList.parentThread = [aDecoder decodeObjectForKey:@"parentThread"];
        newThreadList.pageNumber = [aDecoder decodeIntegerForKey:@"pageNumber"];
        newThreadList.totalPages = [aDecoder decodeIntegerForKey:@"totalPages"];
        newThreadList.threads = [aDecoder decodeObjectForKey:@"threads"];
        newThreadList.lastBatchOfThreads = [aDecoder decodeObjectForKey:@"lastBatchOfThreads"];
        newThreadList.horizontalHeights = [aDecoder decodeObjectForKey:@"horizontalHeights"];
        newThreadList.verticalHeights = [aDecoder decodeObjectForKey:@"verticalHeights"];
        newThreadList.baseURLString = [aDecoder decodeObjectForKey:@"baseURLString"];
        newThreadList.currentOffSet = [[aDecoder decodeObjectForKey:@"currentOffSet"] CGPointValue];
        return newThreadList;
        
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    return nil;
}

@end
