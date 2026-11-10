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

typedef NS_ENUM(NSInteger, czzHistoryListType) {
    czzHistoryListTypeBrowser,
    czzHistoryListTypePosted,
    czzHistoryListTypeResponded
};

@interface czzHistoryManager : NSObject
@property (nonatomic, strong) NSMutableOrderedSet<czzThread *> *browserHistory;
@property (nonatomic, strong) NSMutableOrderedSet<czzThread *> *respondedThreads;
@property (nonatomic, strong) NSMutableOrderedSet<czzThread *> *postedThreads;
@property (nonatomic, readonly) NSString *historyFolder;

- (void)addToRespondedList:(czzThread*)thread;
- (void)addToPostedList:(czzThread *)postedThread;

-(void)recordThread:(czzThread*)thread;
-(BOOL)removeThread:(czzThread*)thread;
/// Removes the thread from one history list only, leaving the other two intact.
-(BOOL)removeThread:(czzThread*)thread fromList:(czzHistoryListType)listType;
-(void)clearRecord;
-(void)saveCurrentState;

+(instancetype)sharedInstance;
@end
