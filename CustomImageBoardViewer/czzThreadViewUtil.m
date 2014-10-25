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


-(void)saveThreadsToCache {
    [[czzThreadCacheManager sharedInstance] saveThreads:subThreads forThread:parentThread];
    [[czzThreadCacheManager sharedInstance] saveVerticalHeights:heightsForRows andHorizontalHeighs:heightsForRowsForHorizontal ForThread:parentThread];

}

@end
