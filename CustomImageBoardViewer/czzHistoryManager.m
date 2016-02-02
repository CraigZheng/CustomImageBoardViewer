//
//  czzHistoryManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 22/12/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzHistoryManager.h"

#import "czzThreadDownloader.h"

@interface czzHistoryManager()
@property (strong, nonatomic) czzThreadDownloader *threadDownloader;

@end

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
    if (browserHistory.count > HISTORY_UPPER_LIMIT - 1) {
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
        DDLogDebug(@"%@", exception);
    }

}

-(void)saveCurrentState {
    NSString *cacheFile = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:HISTORY_CACHE_FILE];
    if (![NSKeyedArchiver archiveRootObject:browserHistory toFile:cacheFile]) {
        DDLogDebug(@"unable to save browser history");
    }
}

#pragma mark - Record posts and responds.

-(void)addToRespondedList:(czzThread *)thread {
    if (self.respondedThreads.count > 5) {
        // If the responded history is bigger than 5, remove the oldest.
        [self.respondedThreads removeObjectAtIndex:0];
    }
    [self.respondedThreads addObject:thread];
    [self saveCurrentState];
}

- (void)addToPostedList:(NSString *)title content:(NSString *)content hasImage:(BOOL)hasImage forum:(czzForum *)forum {
    self.threadDownloader = [czzThreadDownloader new];
    self.threadDownloader.pageNumber = 1;
    self.threadDownloader.parentForum = forum;
    // In completion handler, compare the downloaded threads and see if there's any that is matching.
    self.threadDownloader.completionHandler = ^(BOOL success, NSArray *downloadedThreads, NSError *error){
        DDLogDebug(@"%s, error: %@", __PRETTY_FUNCTION__, error);
        for (czzThread *thread in downloadedThreads) {
            // Compare title and content.
            czzThread *postThread;
            // TODO: compare the title and content only when there is a title and content for you to compare.
            if ([thread.title isEqualToString:title] &&
                [thread.content.string isEqualToString:content]) {
                // Compare image.
                if (hasImage) {
                    if (thread.imgSrc.length) {
                        postThread = thread;
                    }
                }
                // No image.
                else if (thread.imgSrc.length == 0) {
                    postThread = thread;
                }
            }
            if (postThread) {
                DDLogDebug(@"Found match: %@", postThread);
                // TODO: add to posted threads.
                break;
            }
        }
    };
    [self.threadDownloader start];
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
