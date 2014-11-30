//
//  czzThreadList.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzThread.h"
#import "czzJSONProcessor.h"
#import "czzXMLDownloader.h"
#import "czzSettingsCentre.h"

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

@interface czzThreadList : NSObject
@property BOOL shouldHideImageForThisForum;
@property NSString *forumName;
@property NSInteger pageNumber;
@property NSMutableArray *threads;
@property NSArray *lastBatchOfThreads;
@property id<czzThreadListProtocol> delegate;
@property BOOL isDownloading;
@property BOOL isProcessing;

-(void)refresh;
-(void)loadMoreThreads;
-(void)loadMoreThreads:(NSInteger)pageNumber;
@end
