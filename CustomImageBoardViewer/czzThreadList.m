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
@synthesize forumName;
@synthesize pageNumber;
@synthesize delegate;
@synthesize lastBatchOfThreads;
@synthesize isDownloading, isProcessing;
@synthesize horizontalHeights, verticalHeights;
@synthesize parentViewController;

-(instancetype)init {
    self = [super init];
    if (self) {
        baseURLString = [settingCentre thread_list_host];
        threadListProcessor = [czzJSONProcessor new];
        threadListProcessor.delegate = self;
        isDownloading = NO;
        isProcessing = NO;
        threads = [NSMutableArray new];
        horizontalHeights = [NSMutableArray new];
        verticalHeights = [NSMutableArray new];
    }
    return self;
}

-(void)setForumName:(NSString *)name {
    forumName = name;
    baseURLString = [[settingCentre thread_list_host] stringByAppendingString:[forumName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
    [self loadMoreThreads:++pageNumber];
}

-(void)loadMoreThreads:(NSInteger)pn {
    if (xmlDownloader)
        [xmlDownloader stop];
    pageNumber = pn;
    NSString *targetURLStringWithPN = [baseURLString stringByAppendingString:[NSString stringWithFormat:@"?page=%ld", (long)pageNumber]];
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

/*
 calculate heights for both horizontal and vertical of the parent view controller
 */
-(void)calculateHeightsForThreads:(NSArray*)newThreads {
    CGFloat shortWidth, longWidth;
    shortWidth = MIN([UIScreen mainScreen].applicationFrame.size.height, [UIScreen mainScreen].applicationFrame.size.width);
    longWidth = MAX([UIScreen mainScreen].applicationFrame.size.width, [UIScreen mainScreen].applicationFrame.size.height);
    dispatch_async(dispatch_get_main_queue(), ^{
        for (czzThread *thread in newThreads) {
            CGFloat shortHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:parentViewController.view forWidth:shortWidth hasImage:thread.imgSrc.length > 0];
            CGFloat longHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:parentViewController.view forWidth:longWidth hasImage:thread.imgSrc.length > 0];
            [verticalHeights addObject:[NSNumber numberWithFloat:shortHeight]];
            [horizontalHeights addObject:[NSNumber numberWithFloat:longHeight]];
        }
    });
}
@end
