//
//  czzFavouriteManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 23/12/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzFavouriteManager.h"
#import "czzAppDelegate.h"

@interface czzFavouriteManager()
@property (nonatomic, readonly) NSString *favouriteFilePath;
@end

@implementation czzFavouriteManager
@synthesize favouriteThreads;

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

    [self saveCurrentState];
}

-(BOOL)isThreadFavourited:(czzThread *)thread {
    return [self.favouriteThreads containsObject:thread];
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
    if (![NSKeyedArchiver archiveRootObject:favouriteThreads toFile:self.favouriteFilePath]) {
        DDLogDebug(@"can not save favourite threads to %@", self.favouriteFilePath);
    }
}

-(void)restorePreviousState {
    @try {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.favouriteFilePath]) {
            NSSet *tempSet = [NSKeyedUnarchiver unarchiveObjectWithFile:self.favouriteFilePath];
            if (tempSet) {
                NSArray *sortedArray = [self sortTheGivenArray:[tempSet allObjects]];
                favouriteThreads = [[NSMutableOrderedSet alloc] initWithArray:sortedArray];
            }
        }
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
        favouriteThreads = [NSMutableOrderedSet new];
    }
}

- (NSString *)favouriteFilePath {
    return [[[czzAppDelegate documentFolder] stringByAppendingPathComponent:@"Favourite"] stringByAppendingPathComponent:FAVOURITE_THREAD_CACHE_FILE];
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
