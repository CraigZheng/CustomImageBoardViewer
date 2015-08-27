//
//  czzFavouriteManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 23/12/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzFavouriteManager.h"
#import "czzAppDelegate.h"

@implementation czzFavouriteManager
@synthesize favouriteThreads;
@synthesize verticalHeights, horizontalHeights;

-(instancetype)init {
    self = [super init];
    
    if (self) {
        favouriteThreads = [NSMutableOrderedSet new];
        [self restorePreviousState];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(entersBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

-(void)addFavourite:(czzThread *)thread {
    [favouriteThreads addObject:thread];
    //sort after modification
    NSArray *sortedArray = [self sortTheGivenArray:[favouriteThreads array]];
    favouriteThreads = [[NSMutableOrderedSet alloc] initWithArray:sortedArray];
    verticalHeights = nil;
    horizontalHeights = nil;

    [self saveCurrentState];
}

-(BOOL)removeFavourite:(czzThread *)thread {
    if ([favouriteThreads containsObject:thread])
    {
        [favouriteThreads removeObject:thread];
        //sort after modification
        NSArray *sortedArray = [self sortTheGivenArray:[favouriteThreads array]];
        favouriteThreads = [[NSMutableOrderedSet alloc] initWithArray:sortedArray];

        [self saveCurrentState];
        return YES;
    }
    return NO;
}

-(void)removeAll {
    favouriteThreads = [NSMutableOrderedSet new];
    [self saveCurrentState];
}

-(void)entersBackground {
    [self saveCurrentState];
}

-(void)saveCurrentState {
    NSString *cacheFile = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:FAVOURITE_THREAD_CACHE_FILE];
    if (![NSKeyedArchiver archiveRootObject:favouriteThreads toFile:cacheFile]) {
        DLog(@"can not save favourite threads to %@", cacheFile);
    }
}

-(void)restorePreviousState {
    @try {
        NSString *cacheFile = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:FAVOURITE_THREAD_CACHE_FILE];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
            NSSet *tempSet = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile];
            if (tempSet) {
                NSArray *sortedArray = [self sortTheGivenArray:[tempSet allObjects]];
                favouriteThreads = [[NSMutableOrderedSet alloc] initWithArray:sortedArray];
            }
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
        favouriteThreads = [NSMutableOrderedSet new];
    }
}

#pragma sort array - sort the threads so they arrange with ID
-(NSArray*)sortTheGivenArray:(NSArray*)array{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ID" ascending:NO];
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    return sortedArray;
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
