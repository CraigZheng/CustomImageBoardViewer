//
//  czzWatchListManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "czzThread.h"

@interface czzWatchListManager : NSObject <NSCoding>
@property (nonatomic, strong) NSMutableOrderedSet *watchedThreads;
@property (nonatomic, strong) NSArray *updatedThreads;

@property NSMutableArray *verticalHeights;
@property NSMutableArray *horizontalHeights;

-(void)addToWatchList:(czzThread*)thread;
-(void)removeFromWatchList:(czzThread*)thread;

-(void)refreshWatchedThreads:(void(^)(NSArray* threads))completionHandler;

+(instancetype)sharedManager;
@end
