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
@property (nonatomic, readonly) NSString *cacheFile;
@end

@implementation czzHomeViewModelManager

-(instancetype)init {
    self = [super init];
    if (self) {
        self.isDownloading = NO;
        self.isProcessing = NO;
        self.pageNumber = self.totalPages = 1;

    }
    return self;
}

#pragma mark - state perserving/restoring
-(NSString*)saveCurrentState {
    NSString *cachePath = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:self.cacheFile];
    if ([NSKeyedArchiver archiveRootObject:self toFile:cachePath]) {
        DLog(@"save state successed");
        return cachePath;
    } else {
        DLog(@"save state failed");
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
            czzHomeViewModelManager *tempThreadList = [NSKeyedUnarchiver unarchiveObjectWithData:cacheData];
            //copy data
            if (tempThreadList && [tempThreadList isKindOfClass:[czzHomeViewModelManager class]])
            {
                self.forum = tempThreadList.forum;
                self.pageNumber = tempThreadList.pageNumber;
                self.totalPages = tempThreadList.totalPages;
                self.threads = tempThreadList.threads;
                self.verticalHeights = tempThreadList.self.verticalHeights;
                self.horizontalHeights = tempThreadList.self.horizontalHeights;
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

#pragma mark - reload/refresh actions
- (void)reloadData {
    if ([self.delegate respondsToSelector:@selector(viewModelManagerWantsToReload:)]) {
        [self.delegate viewModelManagerWantsToReload:self];
    }
}

-(void)refresh {
    [self removeAll];
    [self loadMoreThreads:self.pageNumber];
}

-(void)loadMoreThreads {
    [self loadMoreThreads:self.pageNumber + 1];
}

-(void)loadMoreThreads:(NSInteger)pn {
#ifdef UNITTEST
    NSData *mockData = [[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"threadList" ofType:@"json"]]];
    [self downloadOf:nil successed:YES result:mockData];
    return;
#endif
    if (self.threadDownloader)
        [self.threadDownloader stop];
    self.pageNumber = pn;
    if (self.pageNumber > self.totalPages)
        self.pageNumber = self.totalPages;

    NSString *targetURLStringWithPN = [[[self.baseURLString
                                         stringByReplacingOccurrencesOfString:kPageNumber
                                         withString:[NSString stringWithFormat:@"%ld", (long) self.pageNumber]]
                                        stringByReplacingOccurrencesOfString:kForumID
                                        withString:[NSString stringWithFormat:@"%ld", (long)self.forum.forumID]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    self.threadDownloader = [[czzURLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
    self.isDownloading = YES;
    if ([self.delegate respondsToSelector:@selector(viewModelManagerBeginDownloading:)]) {
        [self.delegate viewModelManagerBeginDownloading:self];
    }
}

-(void)removeAll {
    self.pageNumber = 1;
    // Keep old threads in the cache
    self.cachedThreads = self.threads;
    self.cachedHorizontalHeights = self.horizontalHeights;
    self.cachedVerticalHeights = self.verticalHeights;
    
    // Clear all.
    self.lastBatchOfThreads = self.horizontalHeights = self.verticalHeights = self.threads = nil;
}

- (void)scrollToContentOffset:(CGPoint)offset {
    if ([self.delegate respondsToSelector:@selector(viewModelManager:wantsToScrollToContentOffset:)]) {
        [self.delegate viewModelManager:self wantsToScrollToContentOffset:offset];
    }
}

- (void)downloadThumbnailsForThreads:(NSArray*)threads {
    for (czzThread *thread in threads) {
        if (thread.thImgSrc.length != 0){
            NSString *targetImgURL;
            if ([thread.thImgSrc hasPrefix:@"http"])
                targetImgURL = thread.thImgSrc;
            else
                targetImgURL = [[settingCentre thumbnail_host] stringByAppendingPathComponent:thread.thImgSrc];
            //if is set to show image
            if ([settingCentre userDefShouldDisplayThumbnail] || ![settingCentre shouldDisplayThumbnail]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[czzImageCentre sharedInstance] downloadThumbnailWithURL:targetImgURL isCompletedURL:YES];
                });
            }
        }
    }
}

#pragma mark - czzURLDownloaderDelegate
-(void)downloadOf:(NSURL *)targetURL successed:(BOOL)successed result:(NSData *)xmlData{
    [self.threadDownloader stop];
    self.threadDownloader = nil;
    self.isDownloading = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(viewModelManager:downloadSuccessful:)]) {
            [self.delegate viewModelManager:self downloadSuccessful:successed];
        }
    });
    if (successed){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.isProcessing = YES;
            [self.threadDataProcessor processThreadListFromData:xmlData forForum:self.forum];
        });
    }
}

-(void)downloadUpdated:(czzURLDownloader *)downloader progress:(CGFloat)progress {
    if ([self.delegate respondsToSelector:@selector(viewModelManager:downloadProgressUpdated:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate viewModelManager:self downloadProgressUpdated:progress];
        });
    }
}

#pragma mark - czzJSONProcesserProtocol
-(void)threadListProcessed:(czzJSONProcessor *)processor :(NSArray *)newThreads :(BOOL)success {
    self.isProcessing = NO;
    if (success){
        self.cachedVerticalHeights = self.cachedHorizontalHeights = self.cachedThreads = nil;
        if (self.shouldHideImageForThisForum)
        {
            for (czzThread *thread in newThreads) {
                thread.thImgSrc = nil;
            }
        }
        [self downloadThumbnailsForThreads:newThreads];
        //process the returned data and pass into the array
        self.lastBatchOfThreads = newThreads;
        [self.threads addObjectsFromArray:newThreads];
        //calculate heights for both vertical and horizontal
        [self calculateHeightsForThreads:self.lastBatchOfThreads];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(viewModelManager:processedThreadData:newThreads:allThreads:)]) {
            [self.delegate viewModelManager:self processedThreadData:success newThreads:self.lastBatchOfThreads allThreads:self.threads];
        }
        DLog(@"%@", NSStringFromSelector(_cmd));
    });
}

-(void)pageNumberUpdated:(NSInteger)currentPage inAllPage:(NSInteger)allPage {
    self.pageNumber = currentPage;
    self.totalPages = allPage;
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

#pragma mark - Setters
-(void)setForum:(czzForum *)forum {
    _forum = forum;
}

#pragma mark - Getters
- (czzJSONProcessor *)threadDataProcessor {
    if (!_threadDataProcessor) {
        _threadDataProcessor = [czzJSONProcessor new];
        _threadDataProcessor.delegate = self;
    }
    return _threadDataProcessor;
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

- (NSMutableArray *)horizontalHeights {
    if (!_horizontalHeights) {
        _horizontalHeights = [NSMutableArray new];
    }
    if (!_horizontalHeights.count && self.cachedHorizontalHeights.count) {
        return self.cachedHorizontalHeights;
    }
    return _horizontalHeights;
}

- (NSMutableArray *)verticalHeights {
    if (!_verticalHeights) {
        _verticalHeights = [NSMutableArray new];
    }
    if (!_verticalHeights.count && self.cachedVerticalHeights.count) {
        return self.cachedVerticalHeights;
    }
    return _verticalHeights;
}

- (NSString *)baseURLString{
    return [[settingCentre thread_list_host] stringByReplacingOccurrencesOfString:kForum withString:[NSString stringWithFormat:@"%@", self.forum.name]];
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
    [aCoder encodeObject:self.horizontalHeights forKey:@"self.horizontalHeights"];
    [aCoder encodeObject:self.verticalHeights forKey:@"self.verticalHeights"];
    [aCoder encodeObject:[NSValue valueWithCGPoint:self.currentOffSet] forKey:@"currentOffSet"];
    [aCoder encodeObject:self.displayedThread forKey:@"displayedThread"];
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
        newThreadList.currentOffSet = [[aDecoder decodeObjectForKey:@"currentOffSet"] CGPointValue];
        newThreadList.displayedThread = [aDecoder decodeObjectForKey:@"displayedThread"];
        return newThreadList;

    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
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

+ (void)setSharedManager:(czzHomeViewModelManager *)manager {
    _sharedObject = manager;
}

@end
