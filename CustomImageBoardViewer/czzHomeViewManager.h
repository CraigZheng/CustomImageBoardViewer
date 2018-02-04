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
#import "czzSettingsCentre.h"
#import "czzAppDelegate.h"
#import "czzThreadDownloader.h"

#import "NSObjectUtil.h"
#import <Foundation/Foundation.h>

@class czzHomeViewManager, ContentPage;
@protocol czzHomeViewManagerDelegate <NSObject>
@optional
-(void)viewManagerDownloadStateChanged:(czzHomeViewManager*)homeViewManager;
-(void)homeViewManager:(czzHomeViewManager*)homeViewManager threadListProcessed:(BOOL)wasSuccessul newThreads:(NSArray*)newThreads allThreads:(NSArray*)allThreads;
-(void)homeViewManager:(czzHomeViewManager*)homeViewManager threadContentProcessed:(BOOL)wasSuccessul newThreads:(NSArray*)newThreads allThreads:(NSArray*)allThreads;
- (void)homeViewManager:(czzHomeViewManager*)homeViewManager wantsToScrollToContentOffset:(CGPoint)offset;

//updates
-(void)homeViewManager:(czzHomeViewManager*)homeViewManager downloadProgressUpdated:(CGFloat)progress;
-(void)homeViewManager:(czzHomeViewManager*)homeViewManager downloadSuccessful:(BOOL)wasSuccessful;

// Need to reload
-(void)homeViewManagerWantsToReload:(czzHomeViewManager*)manager;
-(void)homeViewManager:(czzHomeViewManager*)homeViewManager wantsToShowContentForThread:(czzThread*)thread;

@end

@interface czzHomeViewManager : NSObject <NSCoding, czzThreadDownloaderDelegate>
@property (nonatomic, assign) BOOL shouldHideImageForThisForum;
@property (nonatomic, strong) czzForum *forum;
@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, assign) NSInteger totalPages;
@property (nonatomic, strong) NSMutableArray<ContentPage *> *threads;
@property (nonatomic, strong) NSArray *lastBatchOfThreads;
@property (nonatomic, weak) id<czzHomeViewManagerDelegate> delegate;
@property (nonatomic, readonly) BOOL isDownloading;
@property (nonatomic, readonly) NSString *baseURLString;
@property (nonatomic, assign) CGPoint currentOffSet;
@property (nonatomic, strong) czzThread *displayedThread;
@property (nonatomic, strong) ContentPage *latestResponses;
@property (nonatomic, strong) czzThreadDownloader *downloader;
@property (nonatomic, assign) BOOL isShowingLatestResponse;

- (void)refresh;
- (void)reloadData;
- (void)loadPreviousPage;
- (void)loadMoreThreads;
- (void)loadMoreThreads:(NSInteger)pageNumber;
- (void)loadLatestResponse;
- (void)removeAll;

- (void)scrollToContentOffset:(CGPoint)offset;
- (void)showContentWithThread:(czzThread*)thread;
- (void)highlightUID:(NSString *)UID;
- (void)blockUID:(NSString *)UID;

//save and restore
- (NSString*)saveCurrentState;
- (void)restorePreviousState;

+ (instancetype)sharedManager;
+ (void)setSharedManager:(czzHomeViewManager*)manager;
@end
