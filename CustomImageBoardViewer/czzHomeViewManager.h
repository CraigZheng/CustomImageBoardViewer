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

@class czzHomeViewManager;
@protocol czzHomeViewManagerDelegate <NSObject>
@optional
-(void)viewModelManagerBeginDownloading:(czzHomeViewManager*)threadList;
-(void)viewModelManager:(czzHomeViewManager*)threadList processedThreadData:(BOOL)wasSuccessul newThreads:(NSArray*)newThreads allThreads:(NSArray*)allThreads;
-(void)viewModelManager:(czzHomeViewManager*)threadList processedSubThreadData:(BOOL)wasSuccessul newThreads:(NSArray*)newThreads allThreads:(NSArray*)allThreads;
- (void)viewModelManager:(czzHomeViewManager*)viewModelManager wantsToScrollToContentOffset:(CGPoint)offset;

//updates
-(void)viewModelManager:(czzHomeViewManager*)threadList downloadProgressUpdated:(CGFloat)progress;
-(void)viewModelManager:(czzHomeViewManager*)threadList downloadSuccessful:(BOOL)wasSuccessful;

// Need to reload
-(void)viewModelManagerWantsToReload:(czzHomeViewManager*)manager;

@end

@interface czzHomeViewManager : NSObject <czzURLDownloaderProtocol, czzJSONProcessorDelegate, NSCoding>
@property (nonatomic, assign) BOOL shouldHideImageForThisForum;
@property (nonatomic, strong) czzForum *forum;
@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, assign) NSInteger totalPages;
@property (nonatomic, strong) NSMutableArray *threads;
@property (nonatomic, strong) NSArray *lastBatchOfThreads;
@property (nonatomic, weak) id<czzHomeViewManagerDelegate> delegate;
@property (nonatomic, assign) BOOL isDownloading;
@property (nonatomic, assign) BOOL isProcessing;
@property (nonatomic, strong) NSMutableDictionary *horizontalHeights;
@property (nonatomic, strong) NSMutableDictionary *verticalHeights;
@property (nonatomic, readonly) NSString *baseURLString;
@property (nonatomic, assign) CGPoint currentOffSet;
@property (nonatomic, strong) czzThread *displayedThread;
@property (nonatomic, strong) NSMutableArray *cachedThreads;
@property (nonatomic, strong) NSMutableDictionary *cachedHorizontalHeights;
@property (nonatomic, strong) NSMutableDictionary *cachedVerticalHeights;

// Watch kit completion handler - for temporarily setting the delegate to the watch kit manager
@property (copy)void(^watchKitCompletionHandler)(BOOL success, NSArray* threads);

@property (nonatomic, strong) czzURLDownloader *threadDownloader;
@property (nonatomic, strong) czzJSONProcessor *threadDataProcessor;

-(void)refresh;
-(void)reloadData;
-(void)loadMoreThreads;
-(void)loadMoreThreads:(NSInteger)pageNumber;
-(void)removeAll;
//-(void)calculateHeightsForThreads:(NSArray*)newThreads;
-(void)downloadThumbnailsForThreads:(NSArray*)threads;
-(void)scrollToContentOffset:(CGPoint)offset;

//save and restore
-(NSString*)saveCurrentState;
-(void)restorePreviousState;

+(instancetype)sharedManager;
+(void)setSharedManager:(czzHomeViewManager*)manager;
@end
