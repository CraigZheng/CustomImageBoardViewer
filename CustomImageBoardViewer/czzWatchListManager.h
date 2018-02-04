//
//  czzWatchListManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#define WatchListManager [czzWatchListManager sharedManager]

#import <Foundation/Foundation.h>

#import "czzThread.h"

@interface czzWatchListManager : NSObject <NSCoding>
@property (nonatomic, readonly) NSOrderedSet<czzThread *> *watchedThreads;
@property (nonatomic, strong) NSMutableArray<czzThread *> *updatedThreads;
@property (nonatomic, readonly) NSString *updateSummary;
@property (nonatomic, readonly) NSString *updateTitle;
@property (nonatomic, readonly) NSString *updateContent;
@property (nonatomic, assign) BOOL isDownloading;
@property (readonly, nonatomic) NSString *watchlistFolder;


-(void)addToWatchList:(czzThread*)thread;
-(void)removeFromWatchList:(czzThread*)thread;

-(void)refreshWatchedThreadsWithCompletionHandler:(void(^)(NSArray* updatedThreads))completionHandler;

+(instancetype)sharedManager;
@end
