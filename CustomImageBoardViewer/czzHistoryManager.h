//
//  czzHistoryManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 22/12/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//
#define historyManager [czzHistoryManager sharedInstance]
#define HISTORY_UPPER_LIMIT 100
#define HISTORY_CACHE_FILE @"history_cache.dat"

#import "czzThread.h"
#import "czzAppDelegate.h"

#import <Foundation/Foundation.h>

@interface czzHistoryManager : NSObject 
@property NSMutableOrderedSet *browserHistory;
@property NSMutableArray *verticalHeights;
@property NSMutableArray *horizontalHeights;

-(void)recordThread:(czzThread*)thread;
-(BOOL)removeThread:(czzThread*)thread;
-(void)clearRecord;
-(void)saveCurrentState;

+(instancetype)sharedInstance;
@end
