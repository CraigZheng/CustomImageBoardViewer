//
//  czzHistoryManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 22/12/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzHistoryManager.h"

@implementation czzHistoryManager
@synthesize browserHistory;

-(instancetype)init {
    self = [super init];
    if (self) {
        browserHistory = [NSMutableOrderedSet new];
        [self restorePreviousState];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(entersBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

-(void)entersBackground {
    [self saveCurrentState];
}

-(void)recordThread:(czzThread *)thread {
    if ([browserHistory containsObject:thread])
        [browserHistory removeObject:thread];
    [browserHistory addObject:thread];
    //should not be bigger than 100
    if (browserHistory.count > 99) {
        [browserHistory removeObject:browserHistory.firstObject]; //remove oldest object
    }
    [self saveCurrentState];
}

-(BOOL)removeThread:(czzThread *)thread {
    if ([browserHistory containsObject:thread]) {
        [browserHistory removeObject:thread];
        [self saveCurrentState];
        return YES;
    }
    return NO;
}

-(void)clearRecord {
    [browserHistory removeAllObjects];
    [self saveCurrentState];
}

-(void)restorePreviousState {
    @try {
        NSString *cacheFile = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:HISTORY_CACHE_FILE];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
            NSMutableOrderedSet *tempSet = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile];
            if (tempSet) {
                browserHistory = tempSet;
            }
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }

}

-(void)saveCurrentState {
    NSString *cacheFile = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:HISTORY_CACHE_FILE];
    if (![NSKeyedArchiver archiveRootObject:browserHistory toFile:cacheFile]) {
        DLog(@"unable to save browser history");
    }
}


+ (instancetype)sharedInstance
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}


@end
