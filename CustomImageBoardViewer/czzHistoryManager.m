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
@property (strong, nonatomic) NSString *historyCachePath;
@property (strong, nonatomic) NSString *postedCachePath;
@property (strong, nonatomic) NSString *respondedCachePath;

@end

@implementation czzHistoryManager
@synthesize browserHistory;

-(instancetype)init {
    self = [super init];
    if (self) {
        self.historyCachePath = [self.historyFolder stringByAppendingPathComponent:HISTORY_CACHE_FILE];
        self.postedCachePath = [self.historyFolder stringByAppendingPathComponent:postedHistoryFile];
        self.respondedCachePath = [self.historyFolder stringByAppendingPathComponent:respondedHistoryFile];
        // Check cache files and folders.
        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *error;
        if (![manager fileExistsAtPath:self.historyFolder]){
            [manager createDirectoryAtPath:self.historyFolder
               withIntermediateDirectories:NO
                                attributes:@{NSFileProtectionKey:NSFileProtectionNone}
                                     error:nil];
            DDLogDebug(@"Create document folder: %@", self.historyFolder);
        } else {
            [manager setAttributes:@{NSFileProtectionKey:NSFileProtectionNone}
                      ofItemAtPath:self.historyFolder
                             error:&error];
        }
        // Cache files.
        NSArray *filePaths = @[self.historyCachePath, self.postedCachePath, self.respondedCachePath];
        for (NSString *filePath in filePaths) {
            if ([manager fileExistsAtPath:filePath]) {
                [manager setAttributes:@{NSFileProtectionKey:NSFileProtectionNone}
                          ofItemAtPath:filePath
                                 error:&error];
            } else {
                // Create a new file at the original path with no content and no protection attributes.
                [manager createFileAtPath:filePath
                                 contents:nil
                               attributes:@{NSFileProtectionKey:NSFileProtectionNone}];
            }
        }

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
    if ([browserHistory containsObject:thread] ||
        [self.respondedThreads containsObject:thread] ||
        [self.postedThreads containsObject:thread]) {
        // Remove this thread from all three sets.
        [browserHistory removeObject:thread];
        [self.respondedThreads removeObject:thread];
        [self.postedThreads removeObject:thread];
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
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSMutableOrderedSet *tempSet;
        if ([fileManager fileExistsAtPath:self.historyCachePath]) {
            tempSet = [NSKeyedUnarchiver unarchiveObjectWithFile:self.historyCachePath];
            if (tempSet) {
                browserHistory = tempSet;
            }
        }
        if ([fileManager fileExistsAtPath:self.postedCachePath]) {
            tempSet = [NSKeyedUnarchiver unarchiveObjectWithFile:self.postedCachePath];
            if (tempSet) {
                self.postedThreads = tempSet;
            }
        }
        if ([fileManager fileExistsAtPath:self.respondedCachePath]) {
            tempSet = [NSKeyedUnarchiver unarchiveObjectWithFile:self.respondedCachePath];
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
    if (![NSKeyedArchiver archiveRootObject:browserHistory toFile:self.historyCachePath]) {
        DDLogDebug(@"unable to save browser history");
    }
    if (![NSKeyedArchiver archiveRootObject:self.postedThreads toFile:self.postedCachePath]) {
        DDLogDebug(@"unable to save browser history");
    }
    if (![NSKeyedArchiver archiveRootObject:self.respondedThreads toFile:self.respondedCachePath]) {
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

- (void)addToPostedList:(czzThread *)postedThread {
    // No title, no content, no image, then what are you doing here?
    if (!postedThread) {
        return;
    }
    [self.postedThreads addObject:postedThread];
    if (self.postedThreads.count > HISTORY_UPPER_LIMIT) {
        [self.postedThreads removeObject:self.postedThreads.firstObject];
    }
    [self saveCurrentState];
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

- (NSString *)historyFolder {
    NSString *historyFolder = [[czzAppDelegate documentFolder] stringByAppendingPathComponent:@"History"];
    return historyFolder;
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
