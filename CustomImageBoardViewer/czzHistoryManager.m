//
//  czzHistoryManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 22/12/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzHistoryManager.h"

#import "czzThreadDownloader.h"

static NSString * const postedHistoryFile = @"posted_history_cache.dat";
static NSString * const respondedHistoryFile = @"responded_history_cache.dat";

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
    if (browserHistory.count > HISTORY_UPPER_LIMIT) {
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
    NSString *historyCachePath = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:HISTORY_CACHE_FILE];
    NSString *postedCachePath = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:postedHistoryFile];
    NSString *respondedCachePath = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:respondedHistoryFile];
    @try {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSMutableOrderedSet *tempSet;
        if ([fileManager fileExistsAtPath:historyCachePath]) {
            tempSet = [NSKeyedUnarchiver unarchiveObjectWithFile:historyCachePath];
            if (tempSet) {
                browserHistory = tempSet;
            }
        }
        if ([fileManager fileExistsAtPath:postedCachePath]) {
            tempSet = [NSKeyedUnarchiver unarchiveObjectWithFile:postedCachePath];
            if (tempSet) {
                self.postedThreads = tempSet;
            }
        }
        if ([fileManager fileExistsAtPath:respondedCachePath]) {
            tempSet = [NSKeyedUnarchiver unarchiveObjectWithFile:respondedCachePath];
            if (tempSet) {
                self.respondedThreads = tempSet;
            }
        }
    }
    @catch (NSException *exception) {
        DDLogDebug(@"%@", exception);
    }

}

-(void)saveCurrentState {
    NSString *historyCachePath = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:HISTORY_CACHE_FILE];
    NSString *postedCachePath = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:postedHistoryFile];
    NSString *respondedCachePath = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:respondedHistoryFile];
    if (![NSKeyedArchiver archiveRootObject:browserHistory toFile:historyCachePath]) {
        DDLogDebug(@"unable to save browser history");
    }
    if (![NSKeyedArchiver archiveRootObject:self.postedThreads toFile:postedCachePath]) {
        DDLogDebug(@"unable to save browser history");
    }
    if (![NSKeyedArchiver archiveRootObject:self.respondedThreads toFile:respondedCachePath]) {
        DDLogDebug(@"unable to save browser history");
    }
}

#pragma mark - Record posts and responds.

-(void)addToRespondedList:(czzThread *)thread {
    [self.respondedThreads addObject:thread];
    // Set a limit.
    if (self.respondedThreads.count > HISTORY_UPPER_LIMIT) {
        [self.respondedThreads removeObject:self.respondedThreads.firstObject];
    }
    [self saveCurrentState];
}

- (void)addToPostedList:(NSString *)title content:(NSString *)content hasImage:(BOOL)hasImage forum:(czzForum *)forum {
    // No title, no content, no image, then what are you doing here?
    if (!title.length &&
        !content.length &&
        !hasImage) {
        return;
    }
    self.threadDownloader = [czzThreadDownloader new];
    self.threadDownloader.pageNumber = 1;
    self.threadDownloader.parentForum = forum;
    // In completion handler, compare the downloaded threads and see if there's any that is matching.
    __weak typeof(self) weakSelf = self; // Weak self is for supperssing the warning.
    self.threadDownloader.completionHandler = ^(BOOL success, NSArray *downloadedThreads, NSError *error){
        DDLogDebug(@"%s, error: %@", __PRETTY_FUNCTION__, error);
        for (czzThread *thread in downloadedThreads) {
            // Compare title and content.
            czzThread *matchedThread;
            // TODO: compare the title and content only when there is a title and content for you to compare.
            if ([thread.title isEqualToString:title] &&
                [thread.content.string isEqualToString:content]) {
                // Compare image.
                if (hasImage) {
                    if (thread.imgSrc.length) {
                        matchedThread = thread;
                    }
                }
                // No image.
                else if (thread.imgSrc.length == 0) {
                    matchedThread = thread;
                }
            }
            if (matchedThread) {
                DDLogDebug(@"Found match: %@", matchedThread);
                [weakSelf.postedThreads addObject:matchedThread];
                if (weakSelf.postedThreads.count > HISTORY_UPPER_LIMIT) {
                    [weakSelf.postedThreads removeObject:weakSelf.postedThreads.firstObject];
                }
                [weakSelf saveCurrentState];
                break;
            }
        }
    };
    [self.threadDownloader start];
}

#pragma mark - Getters

- (NSMutableOrderedSet *)postedThreads {
    if (!_postedThreads) {
        _postedThreads = [NSMutableOrderedSet new];
    }
    return _postedThreads;
}

- (NSMutableOrderedSet *)respondedThreads {
    if (!_respondedThreads) {
        _respondedThreads = [NSMutableOrderedSet new];
    }
    return _respondedThreads;
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
