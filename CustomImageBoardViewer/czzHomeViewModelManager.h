//
//  czzThreadList.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define DEFAULT_THREAD_LIST_CACHE_FILE @"DEFAULT_THREAD_LIST_CACHE_FILE.dat"

#import "czzThread.h"
//#import "czzSubThreadList.h"
#import "czzForum.h"

#import "czzJSONProcessor.h"
#import "czzURLDownloader.h"
#import "czzSettingsCentre.h"
#import "czzTextViewHeightCalculator.h"
#import "czzAppDelegate.h"

#import "NSObjectUtil.h"
#import <Foundation/Foundation.h>

@class czzHomeViewModelManager;
@protocol czzThreadListProtocol <NSObject>
@optional
-(void)threadListBeginDownloading:(czzHomeViewModelManager*)threadList;
-(void)threadListProcessed:(czzHomeViewModelManager*)threadList wasSuccessful:(BOOL)wasSuccessul newThreads:(NSArray*)newThreads allThreads:(NSArray*)allThreads;
-(void)subThreadProcessed:(czzHomeViewModelManager*)threadList wasSuccessful:(BOOL)wasSuccessul newThreads:(NSArray*)newThreads allThreads:(NSArray*)allThreads;

//updates
-(void)threadListUpdated:(czzHomeViewModelManager*)threadList progress:(CGFloat)progress;
-(void)threadListDownloaded:(czzHomeViewModelManager*)threadList wasSuccessful:(BOOL)wasSuccessful;

@end

@interface czzHomeViewModelManager : NSObject <czzURLDownloaderProtocol, czzJSONProcessorDelegate, NSCoding>
@property BOOL shouldHideImageForThisForum;
//@property (nonatomic) NSString *forumName;
@property (nonatomic) czzForum *forum;
@property NSInteger pageNumber;
@property NSInteger totalPages;
@property NSMutableArray *threads;
@property NSArray *lastBatchOfThreads;
@property id<czzThreadListProtocol> delegate;
@property BOOL isDownloading;
@property BOOL isProcessing;
@property NSMutableArray *horizontalHeights;
@property NSMutableArray *verticalHeights;
@property NSString *baseURLString;
@property CGPoint currentOffSet;
@property czzThread *displayedThread;

@property czzURLDownloader *threadDownloader;
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
