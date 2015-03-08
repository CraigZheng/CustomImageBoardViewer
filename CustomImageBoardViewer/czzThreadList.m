//
//  czzThreadList.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzThreadList.h"

@interface czzThreadList ()
@end

@implementation czzThreadList
@synthesize xmlDownloader;
@synthesize threadListProcessor;
@synthesize baseURLString;
@synthesize shouldHideImageForThisForum;
@synthesize threads;
@synthesize subThreadProcessor;
//@synthesize forumName;
@synthesize forum;
@synthesize pageNumber;
@synthesize totalPages;
@synthesize delegate;
@synthesize lastBatchOfThreads;
@synthesize isDownloading, isProcessing;
@synthesize horizontalHeights, verticalHeights;
@synthesize parentViewController;
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
        horizontalHeights = [NSMutableArray new];
        verticalHeights = [NSMutableArray new];

        threadListProcessor = [czzJSONProcessor new];
        threadListProcessor.delegate = self;
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
            czzThreadList *tempThreadList = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile];
            //always delete the cache file after reading it to ensure safety
            [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
            //copy data
            if (tempThreadList && [tempThreadList isKindOfClass:[czzThreadList class]])
            {
//                forumName = tempThreadList.forumName;
                self.forum = tempThreadList.forum;
                self.pageNumber = tempThreadList.pageNumber;
                self.totalPages = tempThreadList.totalPages;
                self.threads = tempThreadList.threads;
                self.verticalHeights = tempThreadList.verticalHeights;
                self.horizontalHeights = tempThreadList.horizontalHeights;
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

-(void)setParentViewController:(UIViewController *)viewCon {
    parentViewController = viewCon;
    //register an obverser while adding a parent view controller
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(entersBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

//-(void)setForumName:(NSString *)name {
//    forumName = name;
//    baseURLString = [[settingCentre thread_list_host] stringByAppendingString:forumName ? [forumName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @""];
//}

-(void)setForum:(czzForum *)fo {
    forum = fo;
    baseURLString = [[settingCentre thread_list_host] stringByReplacingOccurrencesOfString:kForumID withString:[NSString stringWithFormat:@"%ld", (long)forum.forumID]];
    DLog(@"forum picked:%@ - base URL: %@", forum.name, baseURLString);
}

-(void)refresh {
    threads = [NSMutableArray new];
    horizontalHeights = [NSMutableArray new];
    verticalHeights = [NSMutableArray new];
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
    if (xmlDownloader)
        [xmlDownloader stop];
    pageNumber = pn;
//    NSString *targetURLStringWithPN = [baseURLString stringByAppendingString:[NSString stringWithFormat:@"?page=%ld", (long)pageNumber]];
    NSString *targetURLStringWithPN = [baseURLString stringByReplacingOccurrencesOfString:kPage withString:[NSString stringWithFormat:@"%ld", (long) pn]];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
    isDownloading = YES;
    if (delegate && [delegate respondsToSelector:@selector(threadListBeginDownloading:)]) {
        [delegate threadListBeginDownloading:self];
    }
}

-(void)removeAll {
    pageNumber = 1;
    [threads removeAllObjects];
    lastBatchOfThreads = nil;
    [horizontalHeights removeAllObjects];
    [verticalHeights removeAllObjects];
}

#pragma czzXMLDownloader - thread xml data received
-(void)downloadOf:(NSURL *)targetURL successed:(BOOL)successed result:(NSData *)xmlData{
    [xmlDownloader stop];
    xmlDownloader = nil;
    isDownloading = NO;
    if (successed){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            isProcessing = YES;
            [threadListProcessor processThreadListFromData:xmlData];
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (delegate && [delegate respondsToSelector:@selector(threadListDownloaded:wasSuccessful:)]) {
            [delegate threadListDownloaded:self wasSuccessful:successed];
        }
    });
}

-(void)downloadUpdated:(czzXMLDownloader *)downloader progress:(CGFloat)progress {
    if (delegate && [delegate respondsToSelector:@selector(threadListUpdated:progress:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate threadListUpdated:self progress:progress];
        });
    }
}

#pragma mark - czzJSONProcesserProtocol
-(void)threadListProcessed:(czzJSONProcessor *)processor :(NSArray *)newThreads :(BOOL)success {
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
            CGFloat shortHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:parentViewController.view forWidth:shortWidth hasImage:thread.imgSrc.length > 0 withExtra:NO];
            CGFloat longHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:parentViewController.view forWidth:longWidth hasImage:thread.imgSrc.length > 0 withExtra:YES];
            [verticalHeights addObject:[NSNumber numberWithFloat:shortHeight]];
            [horizontalHeights addObject:[NSNumber numberWithFloat:longHeight]];
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
    [aCoder encodeObject:horizontalHeights forKey:@"horizontalHeights"];
    [aCoder encodeObject:verticalHeights forKey:@"verticalHeights"];
    [aCoder encodeObject:baseURLString forKey:@"baseURLString"];
    [aCoder encodeObject:[NSValue valueWithCGPoint:currentOffSet] forKey:@"currentOffSet"];
    [aCoder encodeObject:displayedThread forKey:@"displayedThread"];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    czzThreadList *newThreadList = [czzThreadList new];
    [[NSNotificationCenter defaultCenter] removeObserver:newThreadList];
    @try {
        //create a temporary threadlist object
        newThreadList.shouldHideImageForThisForum = [aDecoder decodeBoolForKey:@"shouldHideImageForThisForum"];
        newThreadList.forum = [aDecoder decodeObjectForKey:@"forum"];
        newThreadList.pageNumber = [aDecoder decodeIntegerForKey:@"pageNumber"];
        newThreadList.totalPages = [aDecoder decodeIntegerForKey:@"totalPages"];
        newThreadList.threads = [aDecoder decodeObjectForKey:@"threads"];
        newThreadList.lastBatchOfThreads = [aDecoder decodeObjectForKey:@"lastBatchOfThreads"];
        newThreadList.horizontalHeights = [aDecoder decodeObjectForKey:@"horizontalHeights"];
        newThreadList.verticalHeights = [aDecoder decodeObjectForKey:@"verticalHeights"];
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
