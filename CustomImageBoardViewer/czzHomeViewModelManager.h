//
//  czzThreadList.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define DEFAULT_THREAD_LIST_CACHE_FILE @"DEFAULT_THREAD_LIST_CACHE_FILE.dat"

#import "czzThread.h"
#import "czzForum.h"

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
-(void)viewModelManagerBeginDownloading:(czzHomeViewModelManager*)threadList;
-(void)viewModelManager:(czzHomeViewModelManager*)threadList processedThreadData:(BOOL)wasSuccessul newThreads:(NSArray*)newThreads allThreads:(NSArray*)allThreads;
-(void)viewModelManager:(czzHomeViewModelManager*)threadList processedSubThreadData:(BOOL)wasSuccessul newThreads:(NSArray*)newThreads allThreads:(NSArray*)allThreads;

//updates
-(void)viewModelManager:(czzHomeViewModelManager*)threadList downloadProgressUpdated:(CGFloat)progress;
-(void)viewModelManager:(czzHomeViewModelManager*)threadList downloadSuccessful:(BOOL)wasSuccessful;

// Need to reload
-(void)viewModelManagerWantsToReload:(czzHomeViewModelManager*)manager;

@end

@interface czzHomeViewModelManager : NSObject <czzURLDownloaderProtocol, czzJSONProcessorDelegate, NSCoding>
@property (nonatomic, assign) BOOL shouldHideImageForThisForum;
@property (nonatomic, strong) czzForum *forum;
@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, assign) NSInteger totalPages;
@property (nonatomic, strong) NSMutableArray *threads;
@property (nonatomic, strong) NSArray *lastBatchOfThreads;
@property (nonatomic, weak) UIViewController<czzThreadListProtocol> *delegate;
@property (nonatomic, assign) BOOL isDownloading;
@property (nonatomic, assign) BOOL isProcessing;
@property (nonatomic, strong) NSMutableArray *horizontalHeights;
@property (nonatomic, strong) NSMutableArray *verticalHeights;
@property (nonatomic, readonly) NSString *baseURLString;
@property (nonatomic, assign) CGPoint currentOffSet;
@property (nonatomic, strong) czzThread *displayedThread;
@property (nonatomic, strong) NSMutableArray *cachedThreads;
@property (nonatomic, strong) NSMutableArray *cachedHorizontalHeights;
@property (nonatomic, strong) NSMutableArray *cachedVerticalHeights;


@property (nonatomic, strong) czzURLDownloader *threadDownloader;
@property (nonatomic, strong) czzJSONProcessor *threadListDataProcessor;
@property (nonatomic, strong) czzJSONProcessor *threadContentListDataProcessor;

-(void)refresh;
-(void)reloadData;
-(void)loadMoreThreads;
-(void)loadMoreThreads:(NSInteger)pageNumber;
-(void)removeAll;
-(void)calculateHeightsForThreads:(NSArray*)newThreads;
-(void)downloadThumbnailsForThreads:(NSArray*)threads;

//save and restore
-(NSString*)saveCurrentState;
-(void)restorePreviousState;

+(instancetype)sharedManager;
@end
