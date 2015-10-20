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
@property (nonatomic, readonly) NSOrderedSet *watchedThreads;
@property (nonatomic, strong) NSMutableOrderedSet *respondedThreads;
@property (nonatomic, strong) NSMutableArray *updatedThreads;

@property (nonatomic, assign) BOOL isDownloading;

-(void)addToWatchList:(czzThread*)thread;
-(void)addToRespondedList:(czzThread*)thread;
-(void)removeFromWatchList:(czzThread*)thread;

-(void)refreshWatchedThreads:(void(^)(NSArray* updatedThreads))completionHandler;

+(instancetype)sharedManager;
@end
