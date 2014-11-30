//
//  czzSubThreadList.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//
#define settingCentre [czzSettingsCentre sharedInstance]

#import "czzSubThreadList.h"


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


-(instancetype)initWithParentThread:(czzThread *)thread {
    self = [super init];
    if (self) {
        parentThread = thread;
        parentID = [NSString stringWithFormat:@"%ld", (long) parentThread.ID];
        subThreadProcessor = [czzJSONProcessor new];
        subThreadProcessor.delegate = self;
        baseURLString = [[settingCentre thread_content_host] stringByAppendingPathComponent:parentID];
    }
    
    return self;
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
    NSLog(@"%@", baseURLString);

    if (delegate && [delegate respondsToSelector:@selector(threadListBeginDownloading:)]) {
        [delegate threadListBeginDownloading:self];
    }
}

#pragma mark - czzXMLDownloaderDelegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData {
    if (successed) {
        [subThreadProcessor processSubThreadFromData:xmlData];
    }
}

-(void)subThreadProcessedForThread:(czzJSONProcessor *)processor :(czzThread *)parentThread :(NSArray *)newThread :(BOOL)success {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}
@end
