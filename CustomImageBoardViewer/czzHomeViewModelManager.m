//
//  czzThreadList.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzHomeViewModelManager.h"
#import "czzImageCentre.h"

@interface czzHomeViewModelManager ()
@end

@implementation czzHomeViewModelManager
@synthesize threadDownloader;
@synthesize threadListDataProcessor;
@synthesize baseURLString;
@synthesize shouldHideImageForThisForum;
@synthesize threads;
@synthesize threadContentListDataProcessor;
@synthesize forum;
@synthesize pageNumber;
@synthesize totalPages;
@synthesize delegate;
@synthesize lastBatchOfThreads;
@synthesize isDownloading, isProcessing;
@synthesize currentOffSet;
@synthesize displayedThread;

-(instancetype)init {
    self = [super init];
    if (self) {
        baseURLString = [settingCentre thread_list_host];
        isDownloading = NO;
        isProcessing = NO;
        pageNumber = totalPages = 1;
        threads = [NSMutableArray new];
        self.horizontalHeights = [NSMutableArray new];
        self.verticalHeights = [NSMutableArray new];

        threadListDataProcessor = [czzJSONProcessor new];
        threadListDataProcessor.delegate = self;
    }
    return self;
}

-(void)entersBackground {
    DLog(@"%@", NSStringFromSelector(_cmd));
    [self saveCurrentState];
}

-(void)saveCurrentState {
    NSString *cachePath = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:DEFAULT_THREAD_LIST_CACHE_FILE];
    if ([NSKeyedArchiver archiveRootObject:self toFile:cachePath]) {
        DLog(@"save state successed");
    } else {
        DLog(@"save state failed");
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
    }
}

-(void)restorePreviousState {
    @try {
        NSString *cacheFile = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:DEFAULT_THREAD_LIST_CACHE_FILE];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
            czzHomeViewModelManager *tempThreadList = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile];
            //always delete the cache file after reading it to ensure safety
            [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
            //copy data
            if (tempThreadList && [tempThreadList isKindOfClass:[czzHomeViewModelManager class]])
            {
                self.forum = tempThreadList.forum;
                self.pageNumber = tempThreadList.pageNumber;
                self.totalPages = tempThreadList.totalPages;
                self.threads = tempThreadList.threads;
                self.self.verticalHeights = tempThreadList.self.verticalHeights;
                self.self.horizontalHeights = tempThreadList.self.horizontalHeights;
                self.baseURLString = tempThreadList.baseURLString;
                self.currentOffSet = tempThreadList.currentOffSet;
                self.lastBatchOfThreads = tempThreadList.lastBatchOfThreads;
                self.shouldHideImageForThisForum = tempThreadList.shouldHideImageForThisForum;
                self.displayedThread = tempThreadList.displayedThread;
            }
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
}

-(void)setForum:(czzForum *)fo {
    forum = fo;
    baseURLString = [forum.forumURL stringByReplacingOccurrencesOfString:kForum withString:[NSString stringWithFormat:@"%@", forum.name]];
    DLog(@"forum picked:%@ - base URL: %@", forum.name, baseURLString);
}

-(void)refresh {
    threads = [NSMutableArray new];
    self.horizontalHeights = [NSMutableArray new];
    self.verticalHeights = [NSMutableArray new];
    lastBatchOfThreads = nil;
    pageNumber = 1;
    [self loadMoreThreads:pageNumber];
}

-(void)loadMoreThreads {
    [self loadMoreThreads:pageNumber + 1];
}

-(void)loadMoreThreads:(NSInteger)pn {
#ifdef UNITTEST
    NSData *mockData = [[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"threadList" ofType:@"json"]]];
    [self downloadOf:nil successed:YES result:mockData];
    return;
#endif
    if (threadDownloader)
        [threadDownloader stop];
    pageNumber = pn;

    NSString *targetURLStringWithPN = [[baseURLString stringByReplacingOccurrencesOfString:kPageNumber withString:[NSString stringWithFormat:@"%ld", (long) pageNumber]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    threadDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
    isDownloading = YES;
    if (delegate && [delegate respondsToSelector:@selector(threadListBeginDownloading:)]) {
        [delegate threadListBeginDownloading:self];
    }
}

-(void)removeAll {
    pageNumber = 1;
    [threads removeAllObjects];
    lastBatchOfThreads = nil;
    [self.horizontalHeights removeAllObjects];
    [self.verticalHeights removeAllObjects];
}

#pragma mark - czzURLDownloaderDelegate
-(void)downloadOf:(NSURL *)targetURL successed:(BOOL)successed result:(NSData *)xmlData{
    [threadDownloader stop];
    threadDownloader = nil;
    isDownloading = NO;
    if (successed){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            isProcessing = YES;
            [threadListDataProcessor processThreadListFromData:xmlData forForum:forum];
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (delegate && [delegate respondsToSelector:@selector(threadListDownloaded:wasSuccessful:)]) {
            [delegate threadListDownloaded:self wasSuccessful:successed];
        }
    });
}

-(void)downloadUpdated:(czzURLDownloader *)downloader progress:(CGFloat)progress {
    if (delegate && [delegate respondsToSelector:@selector(threadListUpdated:progress:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate threadListUpdated:self progress:progress];
        });
    }
}

#pragma mark - czzJSONProcesserProtocol
-(void)threadListProcessed:(czzJSONProcessor *)processor :(NSArray *)newThreads :(BOOL)success {
    for (czzThread *thread in newThreads) {
        if (thread.thImgSrc.length != 0){
            NSString *targetImgURL;
            if ([thread.thImgSrc hasPrefix:@"http"])
                targetImgURL = thread.thImgSrc;
            else
                targetImgURL = [forum.imageHost stringByAppendingPathComponent:thread.thImgSrc];
            //if is set to show image
            if ([settingCentre userDefShouldDisplayThumbnail] || ![settingCentre shouldDisplayThumbnail]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[czzImageCentre sharedInstance] downloadThumbnailWithURL:targetImgURL isCompletedURL:YES];
                });
            }
        }

    }
    
    isProcessing = NO;
    if (success){
        if (shouldHideImageForThisForum)
        {
            for (czzThread *thread in newThreads) {
                thread.thImgSrc = nil;
            }
        }
        //process the returned data and pass into the array
        lastBatchOfThreads = newThreads;
        [threads addObjectsFromArray:newThreads];
        //calculate heights for both vertical and horizontal
        [self calculateHeightsForThreads:lastBatchOfThreads];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (delegate && [delegate respondsToSelector:@selector(threadListProcessed:wasSuccessful:newThreads:allThreads:)]) {
            [delegate threadListProcessed:self wasSuccessful:success newThreads:lastBatchOfThreads allThreads:threads];
        }
        DLog(@"%@", NSStringFromSelector(_cmd));
    });
}

-(void)pageNumberUpdated:(NSInteger)currentPage inAllPage:(NSInteger)allPage {
    pageNumber = currentPage;
    totalPages = allPage;
}

/*
 calculate heights for both horizontal and vertical of the parent view controller
 */
-(void)calculateHeightsForThreads:(NSArray*)newThreads {
    CGFloat shortWidth, longWidth;
    shortWidth = MIN([UIScreen mainScreen].applicationFrame.size.height, [UIScreen mainScreen].applicationFrame.size.width);
    longWidth = MAX([UIScreen mainScreen].applicationFrame.size.width, [UIScreen mainScreen].applicationFrame.size.height);
    dispatch_async(dispatch_get_main_queue(), ^{
        for (czzThread *thread in newThreads) {
            CGFloat shortHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:[UIApplication sharedApplication].keyWindow.rootViewController.view forWidth:shortWidth hasImage:thread.imgSrc.length > 0 withExtra:NO];
            CGFloat longHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:[UIApplication sharedApplication].keyWindow.rootViewController.view forWidth:longWidth hasImage:thread.imgSrc.length > 0 withExtra:YES];
            [self.verticalHeights addObject:[NSNumber numberWithFloat:shortHeight]];
            [self.horizontalHeights addObject:[NSNumber numberWithFloat:longHeight]];
        }
    });
}

#pragma mark - NSCoding
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:shouldHideImageForThisForum forKey:@"shouldHideImageForThisForum"];
    [aCoder encodeObject:forum forKey:@"forum"];
    [aCoder encodeInteger:pageNumber forKey:@"pageNumber"];
    [aCoder encodeInteger:totalPages forKey:@"totalPages"];
    [aCoder encodeObject:threads forKey:@"threads"];
    [aCoder encodeObject:lastBatchOfThreads forKey:@"lastBatchOfThreads"];
    //parent view controller can not be encoded
    //delegate can not be encoded
    //isDownloading and isProcessing should not be encoded
    [aCoder encodeObject:self.horizontalHeights forKey:@"self.horizontalHeights"];
    [aCoder encodeObject:self.verticalHeights forKey:@"self.verticalHeights"];
    [aCoder encodeObject:baseURLString forKey:@"baseURLString"];
    [aCoder encodeObject:[NSValue valueWithCGPoint:currentOffSet] forKey:@"currentOffSet"];
    [aCoder encodeObject:displayedThread forKey:@"displayedThread"];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    czzHomeViewModelManager *newThreadList = [czzHomeViewModelManager new];
    [[NSNotificationCenter defaultCenter] removeObserver:newThreadList];
    @try {
        //create a temporary threadlist object
        newThreadList.shouldHideImageForThisForum = [aDecoder decodeBoolForKey:@"shouldHideImageForThisForum"];
        newThreadList.forum = [aDecoder decodeObjectForKey:@"forum"];
        newThreadList.pageNumber = [aDecoder decodeIntegerForKey:@"pageNumber"];
        newThreadList.totalPages = [aDecoder decodeIntegerForKey:@"totalPages"];
        newThreadList.threads = [aDecoder decodeObjectForKey:@"threads"];
        newThreadList.lastBatchOfThreads = [aDecoder decodeObjectForKey:@"lastBatchOfThreads"];
        newThreadList.self.horizontalHeights = [aDecoder decodeObjectForKey:@"self.horizontalHeights"];
        newThreadList.self.verticalHeights = [aDecoder decodeObjectForKey:@"self.verticalHeights"];
        newThreadList.baseURLString = [aDecoder decodeObjectForKey:@"baseURLString"];
        newThreadList.currentOffSet = [[aDecoder decodeObjectForKey:@"currentOffSet"] CGPointValue];
        newThreadList.displayedThread = [aDecoder decodeObjectForKey:@"displayedThread"];
        return newThreadList;

    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    return nil;
}

@end
