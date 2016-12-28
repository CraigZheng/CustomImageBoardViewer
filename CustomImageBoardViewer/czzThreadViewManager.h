//
//  czzSubThreadList.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define SUB_THREAD_LIST_CACHE_FILE @"_cache.dat"

#import "czzHomeViewManager.h"

@class czzThreadViewManager;
@protocol czzThreadViewManagerDelegate <czzHomeViewManagerDelegate>
@optional
- (void)viewManagerContinousDownloadUpdated:(czzThreadViewManager *)viewManager;
- (void)viewManager:(czzThreadViewManager *)viewManager continousDownloadCompleted:(BOOL)success;
@end

@interface czzThreadViewManager : czzHomeViewManager
@property (strong, nonatomic) NSString* parentID;
@property (weak, nonatomic) czzThread *parentThread;
@property (assign, nonatomic) BOOL restoredFromCache;
@property (weak, nonatomic) id<czzThreadViewManagerDelegate> delegate;
@property (readonly, nonatomic) BOOL isMassiveDownloading;

- (void)reset;
- (void)loadAll;
- (void)stopAllOperation;
- (void)jumpToPage:(NSInteger)page;
- (instancetype)initWithParentThread:(czzThread*)thread andForum:(czzForum*)forum;
- (instancetype)restoreWithFile:(NSString*)filePath;
@end
