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


-(instancetype)initWithParentThread:(czzThread *)thread {
    self = [super init];
    if (self) {
        parentThread = thread;
        parentID = [NSString stringWithFormat:@"%ld", (long) parentThread.ID];
        subThreadProcessor = [czzJSONProcessor new];
        subThreadProcessor.delegate = self;
        baseURLString = [[settingCentre thread_content_host] stringByAppendingPathComponent:parentID];
        
        threads = [NSMutableArray new];
        verticalHeights = [NSMutableArray new];
        horizontalHeights = [NSMutableArray new];
        

    }
    
    return self;
}

-(void)refresh {
    [super refresh];
    threads = [NSMutableArray new];
    [threads addObject:parentThread];
}

-(void)setParentThread:(czzThread *)thread {
    parentThread = thread;
    parentID = [NSString stringWithFormat:@"%ld", (long)parentThread.ID];
    baseURLString = [[settingCentre thread_content_host] stringByAppendingPathComponent:parentID];
}

-(void)loadMoreThreads:(NSInteger)pn {
    if (xmlDownloader)
        [xmlDownloader stop];
    pageNumber = pn;
    NSString *targetURLStringWithPN = [baseURLString stringByAppendingString:[NSString stringWithFormat:@"?page=%ld", (long)pageNumber]];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
    isDownloading = YES;
    NSLog(@"%@", targetURLStringWithPN);
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
}

-(void)subThreadProcessedForThread:(czzJSONProcessor *)processor :(czzThread *)forThread :(NSArray *)newThread :(BOOL)success {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    isProcessing = NO;
    if (success) {
        lastBatchOfThreads = newThread;
        NSArray *processedNewThread;
        if (threads.count > 0) {
            NSInteger lastChunkIndex = threads.count - [settingCentre threads_per_page];
            if (lastChunkIndex < 1)
                lastChunkIndex = 1;
            cutOffIndex = lastChunkIndex;
            NSInteger lastChunkLength = threads.count - lastChunkIndex;
            NSRange lastChunkRange = NSMakeRange(lastChunkIndex, lastChunkLength);
            NSArray *lastChunkOfThread = [threads subarrayWithRange:lastChunkRange];
            NSMutableSet *oldThreadSet = [NSMutableSet setWithArray:lastChunkOfThread];
            [oldThreadSet addObjectsFromArray:newThread];
            [threads removeObjectsInRange:lastChunkRange];
            processedNewThread = [self sortTheGivenArray:oldThreadSet.allObjects];
        } else {
            cutOffIndex = 0;
            NSMutableArray *threadsWithParent = [NSMutableArray new];
            [threadsWithParent addObject:parentThread];
            [threadsWithParent addObjectsFromArray:newThread];
            processedNewThread = [self sortTheGivenArray:threadsWithParent];
        }
        lastBatchOfThreads = processedNewThread;
        [threads addObjectsFromArray:lastBatchOfThreads];
        
        [self calculateHeightsForThreads:lastBatchOfThreads];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (delegate && [delegate respondsToSelector:@selector(subThreadProcessed:wasSuccessful:newThreads:allThreads:)]) {
            [delegate subThreadProcessed:self wasSuccessful:success newThreads:lastBatchOfThreads allThreads:threads];
        }
    });
}

#pragma mark sort array based on thread ID
-(NSArray*)sortTheGivenArray:(NSArray*)array{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ID" ascending:YES];
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:@[sortDescriptor]];
    return sortedArray ? sortedArray : [NSArray new];
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
        [verticalHeights removeObjectsInRange:NSMakeRange(cutOffIndex, verticalHeights.count - cutOffIndex)];
        [horizontalHeights removeObjectsInRange:NSMakeRange(cutOffIndex, verticalHeights.count - cutOffIndex)];
        for (czzThread *thread in newThreads) {
            CGFloat shortHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:parentViewController.view forWidth:shortWidth hasImage:thread.imgSrc.length > 0];
            CGFloat longHeight = [czzTextViewHeightCalculator calculatePerfectHeightForThreadContent:thread inView:parentViewController.view forWidth:longWidth hasImage:thread.imgSrc.length > 0];
            [verticalHeights addObject:[NSNumber numberWithFloat:shortHeight]];
            [horizontalHeights addObject:[NSNumber numberWithFloat:longHeight]];
        }
//        NSLog(@"processing time: %.2f", [[NSDate new] timeIntervalSinceDate:date]);
//        NSLog(@"size of heights array: %lu", verticalHeights.count);
    });
}
@end
