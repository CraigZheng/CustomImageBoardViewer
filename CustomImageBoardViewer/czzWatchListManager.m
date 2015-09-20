//
//  czzWatchListManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWatchListManager.h"
#import "czzThreadViewModelManager.h"
#import "czzMessagePopUpViewController.h"

#define WATCH_LIST_CACHE_FILE @"watchedThreads.dat"

@interface czzWatchListManager ()

@property (nonatomic, strong) NSMutableOrderedSet *watchedThreads;
@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, strong) czzThreadViewModelManager *threadViewModelManager;
@end

@implementation czzWatchListManager

#pragma mark - Life cycle
-(instancetype)init {
    self = [super init];
    [self restoreState];
    return self;
}

-(void)addToWatchList:(czzThread *)thread {
    [self.watchedThreads addObject:thread];
    [self saveState];
}

-(void)removeFromWatchList:(czzThread *)thread {
    [self.watchedThreads removeObject:thread];
}

#pragma mark - Refresh action
-(void)refreshWatchedThreads:(void (^)(NSArray *))completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableArray *updatedThread = [NSMutableArray new];
        for (czzThread *thread in self.watchedThreads) {
            czzThread *newThread = [[czzThread alloc] initWithParentID:thread.ID];
            
            if (thread.responseCount != newThread.responseCount) {
                //Record the old thread with old data, later we will remove it from the OrderedSet, then put it back to update the set.
                [updatedThread addObject:newThread];
            }
        }
        for (czzThread *thread in updatedThread) {
            [self.watchedThreads removeObject:thread];
            [self.watchedThreads addObject:thread];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(updatedThread);
            [self saveState];
        });
    });
}

#pragma mark - State restoration
-(void)restoreState {
    @try {
        czzWatchListManager *tempWatchListManager = [NSKeyedUnarchiver unarchiveObjectWithFile:[[czzAppDelegate libraryFolder] stringByAppendingPathComponent:WATCH_LIST_CACHE_FILE]];
        if (tempWatchListManager && tempWatchListManager.watchedThreads.count) {
            self.watchedThreads = tempWatchListManager.watchedThreads;
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
}

-(void)saveState {
    [NSKeyedArchiver archiveRootObject:self toFile:[[czzAppDelegate libraryFolder] stringByAppendingPathComponent:WATCH_LIST_CACHE_FILE]];
}

#pragma mark - NSCodingDelegate
-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    self.watchedThreads = [aDecoder decodeObjectForKey:@"watchedThreads"];
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.watchedThreads forKey:@"watchedThreads"];
}

#pragma mark - Getters
-(NSMutableOrderedSet *)watchedThreads {
    if (!_watchedThreads) {
        _watchedThreads = [NSMutableOrderedSet new];
    }
    return _watchedThreads;
}

+(instancetype)sharedManager {
    static id sharedManager;
    static dispatch_once_t once_token;
    
    dispatch_once(&once_token, ^{
        sharedManager = [czzWatchListManager new];
    });
    
    return sharedManager;
}
@end
