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
@property (nonatomic, strong) NSMutableOrderedSet *browserHistory;
@property (nonatomic, strong) NSMutableOrderedSet *respondedThreads;
@property (nonatomic, strong) NSMutableOrderedSet *postedThreads;
@property (nonatomic, readonly) NSString *historyFolder;

- (void)addToRespondedList:(czzThread*)thread;
- (void)addToPostedList:(NSString*)title
                content:(NSString*)content
               hasImage:(BOOL)hasImage
                  forum:(czzForum*)forum;

-(void)recordThread:(czzThread*)thread;
-(BOOL)removeThread:(czzThread*)thread;
-(void)clearRecord;
-(void)saveCurrentState;

+(instancetype)sharedInstance;
@end
