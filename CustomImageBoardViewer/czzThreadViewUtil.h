//
//  czzThreadViewUtil.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 26/10/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzThread.h"
#import "czzXMLDownloader.h"
#import "czzJSONProcessor.h"
#import "czzThreadCacheManager.h"
#import "czzSettingsCentre.h"
#import "czzAppDelegate.h"
#import "Toast+UIView.h"

@interface czzThreadViewUtil : NSObject

@property czzThread *parentThread;
@property NSMutableArray *subThreads;
@property NSInteger currentPageNumber;
@property NSMutableArray *heightsForRows;
@property NSMutableArray *heightsForRowsForHorizontal;
@property CGPoint restoreFromBackgroundContentOffset;

-(void)saveThreadsToCache;
@end
