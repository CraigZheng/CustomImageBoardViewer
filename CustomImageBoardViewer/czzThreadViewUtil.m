//
//  czzThreadViewUtil.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 26/10/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzThreadViewUtil.h"

@interface czzThreadViewUtil() <czzXMLDownloaderDelegate, czzJSONProcessorDelegate>
@property czzXMLDownloader *downloader;
@property czzJSONProcessor *jsonProcessor;
@property NSString *baseURLString;
@property czzSettingsCentre *settingsCentre;
@end

@implementation czzThreadViewUtil
@synthesize parentThread;
@synthesize subThreads;
@synthesize currentPageNumber;
@synthesize heightsForRows;
@synthesize heightsForRowsForHorizontal;
@synthesize restoreFromBackgroundContentOffset;
@synthesize downloader;
@synthesize jsonProcessor;
@synthesize baseURLString;
@synthesize settingsCentre;

-(instancetype)init {
    self = [super init];
    if (self) {
        settingsCentre = [czzSettingsCentre sharedInstance];
        baseURLString = [settingsCentre.thread_content_host stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)self.parentThread.ID]];
    }
    return self;
}
-(void)saveThreadsToCache {
    [[czzThreadCacheManager sharedInstance] saveThreads:subThreads forThread:parentThread];
    [[czzThreadCacheManager sharedInstance] saveVerticalHeights:heightsForRows andHorizontalHeighs:heightsForRowsForHorizontal ForThread:parentThread];

}

-(void)loadMoreThread:(NSInteger)pn{
    if (!pn)
        pn = currentPageNumber;
    if (downloader)
        [downloader stop];
    NSString *targetURLStringWithPN = [baseURLString stringByAppendingString:
                                       [NSString stringWithFormat:@"?page=%ld", (long)pn]];
    
    //access token for the server
    NSString *oldToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"access_token"];
    if (oldToken){
        //        targetURLStringWithPN = [targetURLStringWithPN stringByAppendingFormat:@"&access_token=%@", oldToken];
    }
    
    downloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
}

#pragma mark czzXMLDownloader delegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData{
    [downloader stop];
    downloader = nil;
    if (successed) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            jsonProcessor = [czzJSONProcessor new];
            jsonProcessor.delegate = self;
            [jsonProcessor processSubThreadFromData:xmlData];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"无法下载资料，请检查网络" duration:1.2 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
        });
    }
}

#pragma mark - czzJSONProcessorDelegate
-(void)subThreadProcessedForThread:(czzThread *)pThread :(NSArray *)newThread :(BOOL)success{
    if (success){
        NSArray *processedNewThread;
        //the newly downloaded thread might contain duplicate threads, therefore must compare the last chunk of current threads with the new threads, to remove any duplication
        if (subThreads.count > 1) {
            NSInteger lastChunkIndex = subThreads.count - settingsCentre.threads_per_page;
            if (lastChunkIndex < 1)
                lastChunkIndex = 1;
            NSInteger lastChunkLength = subThreads.count - lastChunkIndex;
            NSRange lastChunkRange = NSMakeRange(lastChunkIndex, lastChunkLength);
            NSArray *lastChunkOfThread = [subThreads subarrayWithRange:lastChunkRange];
            NSMutableSet *oldThreadSet = [NSMutableSet setWithArray:lastChunkOfThread];
            [oldThreadSet addObjectsFromArray:newThread];
            [subThreads removeObjectsInRange:lastChunkRange];
            processedNewThread = [self sortTheGivenArray:oldThreadSet.allObjects];
        } else {
            processedNewThread = [self sortTheGivenArray:newThread];
        }

        [subThreads addObjectsFromArray:processedNewThread];
        //swap the first object(the parent thread)
        if (pThread)
            parentThread = pThread;
        [subThreads replaceObjectAtIndex:0 withObject:parentThread];
        //increase page number if enough to fill a page of 20 threads
        if (processedNewThread.count >= 20) {
            currentPageNumber ++;
        }
        NSLog(@"sub threads downloaded: %lu threads in array", (unsigned long)subThreads.count);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"无法下载资料，请检查网络" duration:1.2 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
        });
    }
    
}

#pragma mark sort array based on thread ID
-(NSArray*)sortTheGivenArray:(NSArray*)array{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ID" ascending:YES];
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    return sortedArray ? sortedArray : [NSArray new];
}

@end
