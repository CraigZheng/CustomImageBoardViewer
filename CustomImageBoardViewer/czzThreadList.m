//
//  czzThreadList.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define settingCentre [czzSettingsCentre sharedInstance]

#import "czzThreadList.h"

@interface czzThreadList () <czzXMLDownloaderDelegate, czzJSONProcessorDelegate>
@property czzXMLDownloader *xmlDownloader;
@property czzJSONProcessor *threadListProcessor;
@property czzJSONProcessor *subThreadProcessor;
@property NSString *baseURLString;
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

-(instancetype)init {
    self = [super init];
    if (self) {
        baseURLString = [settingCentre thread_list_host];
        threadListProcessor = [czzJSONProcessor new];
        threadListProcessor.delegate = self;
        subThreadProcessor = [czzJSONProcessor new];
        subThreadProcessor.delegate = self;
        
        threads = [NSMutableArray new];
    }
    return self;
}

-(void)refresh {
    threads = [NSMutableArray new];
    lastBatchOfThreads = nil;
    pageNumber = 1;
}

-(void)loadMoreThreads:(NSInteger)pn {
    if (xmlDownloader)
        [xmlDownloader stop];
    pageNumber = pn;
    NSString *targetURLStringWithPN = [[baseURLString stringByAppendingString:[forumName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] stringByAppendingString:[NSString stringWithFormat:@"?page=%ld", (long)pageNumber]];
    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
}

#pragma czzXMLDownloader - thread xml data received
-(void)downloadOf:(NSURL *)targetURL successed:(BOOL)successed result:(NSData *)xmlData{
    [xmlDownloader stop];
    xmlDownloader = nil;
    if (successed){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [threadListProcessor processThreadListFromData:xmlData];
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (delegate && [delegate respondsToSelector:@selector(threadListDownloaded:wasSuccessful:)]) {
            [delegate threadListDownloaded:self wasSuccessful:successed];
        }
    });
}

#pragma mark - czzJSONProcesserProtocol
-(void)threadListProcessed:(czzJSONProcessor *)processor :(NSArray *)newThreads :(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
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
        }
        
        if (delegate && [delegate respondsToSelector:@selector(threadListProcessed:wasSuccessful:newThreads:allThreads:)]) {
            [delegate threadListProcessed:self wasSuccessful:success newThreads:lastBatchOfThreads allThreads:threads];
        }
        NSLog(@"%@", NSStringFromSelector(_cmd));
    });
}
@end
