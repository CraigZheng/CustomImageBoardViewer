//
//  czzSubThreadList.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

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
@property (weak, nonatomic) id<czzThreadViewManagerDelegate> delegate;
@property (readonly, nonatomic) BOOL isMassiveDownloading;

- (void)reset;
- (void)loadAll;
- (void)stopAllOperation;
- (void)jumpToPage:(NSInteger)page;
- (void)setOnlyShowUserID:(NSString*)userID;
- (instancetype)initWithParentThread:(czzThread*)thread andForum:(czzForum*)forum;

// Remembers the page the reader was on, in NSUserDefaults. This is the "记录页码"
// feature, not the removed thread-content cache; it stores one integer per thread.
- (NSString*)saveCurrentState;
- (void)restorePreviousState;
@end
