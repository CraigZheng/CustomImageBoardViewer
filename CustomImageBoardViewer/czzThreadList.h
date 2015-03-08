//
//  czzThreadList.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define DEFAULT_THREAD_LIST_CACHE_FILE @"DEFAULT_THREAD_LIST_CACHE_FILE.dat"

#define kForumID @"<FORUM_ID>"
#define kPage @"<PAGE>"

#import "czzThread.h"
//#import "czzSubThreadList.h"
#import "czzForum.h"

#import "czzJSONProcessor.h"
#import "czzXMLDownloader.h"
#import "czzSettingsCentre.h"
#import "czzTextViewHeightCalculator.h"
#import "czzAppDelegate.h"

#import "NSObjectUtil.h"
#import <Foundation/Foundation.h>

@class czzThreadList;
@protocol czzThreadListProtocol <NSObject>
@optional
-(void)threadListBeginDownloading:(czzThreadList*)threadList;
-(void)threadListProcessed:(czzThreadList*)threadList wasSuccessful:(BOOL)wasSuccessul newThreads:(NSArray*)newThreads allThreads:(NSArray*)allThreads;
-(void)subThreadProcessed:(czzThreadList*)threadList wasSuccessful:(BOOL)wasSuccessul newThreads:(NSArray*)newThreads allThreads:(NSArray*)allThreads;

//updates
-(void)threadListUpdated:(czzThreadList*)threadList progress:(CGFloat)progress;
-(void)threadListDownloaded:(czzThreadList*)threadList wasSuccessful:(BOOL)wasSuccessful;

@end

@interface czzThreadList : NSObject <czzXMLDownloaderDelegate, czzJSONProcessorDelegate, NSCoding>
@property BOOL shouldHideImageForThisForum;
//@property (nonatomic) NSString *forumName;
@property (nonatomic) czzForum *forum;
@property NSInteger pageNumber;
@property NSInteger totalPages;
@property NSMutableArray *threads;
@property NSArray *lastBatchOfThreads;
@property (nonatomic) UIViewController *parentViewController;
@property id<czzThreadListProtocol> delegate;
@property BOOL isDownloading;
@property BOOL isProcessing;
@property NSMutableArray *horizontalHeights;
@property NSMutableArray *verticalHeights;
@property NSString *baseURLString;
@property CGPoint currentOffSet;
@property czzThread *displayedThread;

@property czzXMLDownloader *xmlDownloader;
@property czzJSONProcessor *threadListProcessor;
@property czzJSONProcessor *subThreadProcessor;

-(void)refresh;
-(void)loadMoreThreads;
-(void)loadMoreThreads:(NSInteger)pageNumber;
-(void)removeAll;
-(void)calculateHeightsForThreads:(NSArray*)newThreads;
//save and restore
-(void)saveCurrentState;
-(void)restorePreviousState;
@end
