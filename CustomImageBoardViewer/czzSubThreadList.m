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

-(void)removeAll {
    pageNumber = 1;
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
    DLog(@"current page: %ld, total pages:%ld", pageNumber, totalPages);
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
    NSDictionary *allPropertie = [NSObjectUtil classPropsFor:self.class];
    for (NSString *key in allPropertie.allKeys) {
        id value = [self valueForKey:key];
        @try {
            if (value)
                [self encodeValue:[self valueForKey:key] forKey:key withEncoder:aCoder];
        }
        @catch (NSException *exception) {
        }
    }
}

-(void)encodeValue:(id)value forKey:(NSString*)key withEncoder:(NSCoder*)coder {
    if ([value isKindOfClass:[NSObject class]])
    {
        [coder encodeObject:value forKey:key];
    } else if ([value isKindOfClass:[NSNumber class]]) {
        [coder encodeObject:value forKey:key];
    }
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    czzSubThreadList *newThreadList = [czzSubThreadList new];
    for (NSString *key in [[NSObjectUtil classPropsFor:newThreadList.class] allKeys]) {
        if (![aDecoder containsValueForKey:key])
            continue;
        id value = [self decodeValueForKey:key withDecoder:aDecoder];
        @try {
            if (value)
                [newThreadList setValue:value forKey:key];
        }
        @catch (NSException *exception) {
        }
    }
    return newThreadList;
}

-(id)decodeValueForKey:(NSString*)key withDecoder:(NSCoder*)coder {
    NSObject *object = [coder decodeObjectForKey:key];
    return object;
}
@end
