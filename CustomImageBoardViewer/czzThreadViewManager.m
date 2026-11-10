//
//  czzSubThreadList.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//
#define settingCentre [czzSettingsCentre sharedInstance]

#import "czzThreadViewManager.h"
#import "czzHistoryManager.h"
#import "czzThreadDownloader.h"
#import "czzMassiveThreadDownloader.h"
#import "czzMarkerManager.h"
#import "czzFavouriteManager.h"
#import "NSArray+Splitting.h"

#import "CustomImageBoardViewer-Swift.h"

typedef enum : NSUInteger {
    ViewManagerLoadingModeNormal,
    ViewManagerLoadingModeJumpping
} ViewManagerLoadingMode;

// Recorded page numbers live in NSUserDefaults, one entry per thread per host. The
// prefix makes them enumerable so they can be pruned; without it the keys were
// indistinguishable from every other preference and grew without limit.
static NSString * const kRecordedPageNumberKeyPrefix = @"czzRecordedPageNumber.";
// Oldest entries beyond this many are dropped, so the store stays bounded even for
// readers who open thousands of threads.
static NSUInteger const kMaxRecordedPageNumbers = 200;
static NSString * const kRecordedPageKey = @"page";
static NSString * const kRecordedPageUpdatedKey = @"updated";

@interface czzThreadViewManager() <czzMassiveThreadDownloaderDelegate>
@property (nonatomic, assign) BOOL pageNumberChanged;
@property (nonatomic, assign) NSInteger previousPageNumber;
@property (nonatomic, strong) czzMassiveThreadDownloader *massiveDownloader;
@property (nonatomic, assign) ViewManagerLoadingMode loadingMode;
@property (nonatomic, readonly) NSInteger totalPages;
@end

@implementation czzThreadViewManager
@synthesize forum = _forum;
@synthesize downloader = _downloader;
@synthesize threads = _threads;
@dynamic delegate, totalPages;

#pragma mark - life cycle.
-(instancetype)initWithParentThread:(czzThread *)thread andForum:(czzForum *)forum{
    self = [self init];
    if (self) {
        self.parentThread = thread;
        // Give it a default forum, can be nil.
        self.forum = forum ?: [czzForum new];
        
        [self reset];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - state perserving/restoring
-(void)restorePreviousState {
    [czzThreadViewManager migrateLegacyRecordedPageNumbersIfNeeded];
    // Restore previous page number.
    id storedRecord = [[NSUserDefaults standardUserDefaults] objectForKey:self.pageNumberKey];
    NSInteger pageNumber = 0;
    if ([storedRecord isKindOfClass:[NSDictionary class]]) {
        pageNumber = [[(NSDictionary *)storedRecord objectForKey:kRecordedPageKey] integerValue];
    }
    self.pageNumber = MAX(1, pageNumber);
}

-(NSString*)saveCurrentState {
    if (self.parentThread.ID <= 0) {
        return nil;
    }
    // self.pageNumber is the page the reader is actually looking at. Reading
    // self.threads.lastObject.pageNumber instead would resume at the furthest page
    // loaded, which differs from where they were after loading an earlier page.
    NSDictionary *record = @{ kRecordedPageKey : @(MAX(1, self.pageNumber)),
                              kRecordedPageUpdatedKey : @([[NSDate date] timeIntervalSince1970]) };
    [[NSUserDefaults standardUserDefaults] setObject:record forKey:self.pageNumberKey];
    [self pruneRecordedPageNumbers];
    return nil;
}

// Earlier versions stored the page as a bare integer under "<host><threadID>". Those
// keys have no prefix and cannot be found by enumeration, so convert them once and
// drop them; otherwise every reader would silently start over at page 1. This is a
// class method so it can run even when the setting is off: with recording disabled
// nothing else would ever visit these keys, and they would linger forever.
+(void)migrateLegacyRecordedPageNumbersIfNeeded {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    static NSString * const kMigrationDoneKey = @"czzRecordedPageNumberMigrated";
    if ([userDefault boolForKey:kMigrationDoneKey]) {
        return;
    }
    NSMutableSet<NSString *> *hosts = [NSMutableSet new];
    for (NSString *host in @[ settingCentre.activeHost ?: @"",
                              settingCentre.ac_isle_host ?: @"",
                              settingCentre.bt_isle_host ?: @"" ]) {
        if (host.length) {
            [hosts addObject:host];
        }
    }
    // A legacy key is a known host prefix followed only by digits.
    NSRegularExpression *digitsOnly = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+$" options:0 error:nil];
    for (NSString *key in userDefault.dictionaryRepresentation.allKeys) {
        if ([key hasPrefix:kRecordedPageNumberKeyPrefix]) {
            continue;
        }
        for (NSString *host in hosts) {
            if (![key hasPrefix:host]) {
                continue;
            }
            NSString *threadID = [key substringFromIndex:host.length];
            if (!threadID.length || [digitsOnly firstMatchInString:threadID options:0 range:NSMakeRange(0, threadID.length)] == nil) {
                continue;
            }
            id legacyValue = [userDefault objectForKey:key];
            if (![legacyValue respondsToSelector:@selector(integerValue)]) {
                continue;
            }
            NSString *newKey = [kRecordedPageNumberKeyPrefix stringByAppendingFormat:@"%@|%@", host, threadID];
            if (![userDefault objectForKey:newKey]) {
                [userDefault setObject:@{ kRecordedPageKey : @(MAX(1, [legacyValue integerValue])),
                                          kRecordedPageUpdatedKey : @([[NSDate date] timeIntervalSince1970]) }
                                forKey:newKey];
            }
            [userDefault removeObjectForKey:key];
            break;
        }
    }
    [userDefault setBool:YES forKey:kMigrationDoneKey];
}

// Drops the oldest recorded pages once the store exceeds kMaxRecordedPageNumbers.
-(void)pruneRecordedPageNumbers {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSMutableArray<NSDictionary *> *records = [NSMutableArray new];
    for (NSString *key in userDefault.dictionaryRepresentation.allKeys) {
        if (![key hasPrefix:kRecordedPageNumberKeyPrefix]) {
            continue;
        }
        id value = [userDefault objectForKey:key];
        NSTimeInterval updated = [value isKindOfClass:[NSDictionary class]]
            ? [[(NSDictionary *)value objectForKey:kRecordedPageUpdatedKey] doubleValue]
            : 0;
        [records addObject:@{ @"key" : key, kRecordedPageUpdatedKey : @(updated) }];
    }
    if (records.count <= kMaxRecordedPageNumbers) {
        return;
    }
    [records sortUsingComparator:^NSComparisonResult(NSDictionary *record1, NSDictionary *record2) {
        return [record1[kRecordedPageUpdatedKey] compare:record2[kRecordedPageUpdatedKey]];
    }];
    NSUInteger excess = records.count - kMaxRecordedPageNumbers;
    for (NSUInteger index = 0; index < excess; index++) {
        NSString *oldestKey = records[index][@"key"];
        if (oldestKey.length) {
            [userDefault removeObjectForKey:oldestKey];
        }
    }
}

#pragma mark - setters
-(void)setParentThread:(czzThread *)thread {
    if (thread) {
        _parentThread = thread;
        self.parentID = [NSString stringWithFormat:@"%ld", (long)self.parentThread.ID];
        [historyManager recordThread:self.parentThread];
        [czzFavouriteManager.sharedInstance updateFavourite:self.parentThread];
    }
}

#pragma mark - czzMassiveThreadDownloaderDelegate

- (void)threadDownloaderCompleted:(czzThreadDownloader *)downloader success:(BOOL)success downloadedThreads:(NSArray *)threads error:(NSError *)error {
    NSInteger previousThreadCount = self.threads.count;
    // Remove the parent thread for easier calculation.
    if (downloader.parentThread.ID > 0) {
        self.parentThread = downloader.parentThread;
        if (self.threads.firstObject.pageNumber == 0) {
            self.threads.firstObject.threads = @[self.parentThread];
        }
    }
    if (success) {
        // Remove any threads with ignored IDs.
        for (NSNumber *ignoredID in settingCentre.ignoredThreadIDs) {
            NSArray *threadsWithIgnoredID = [threads filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"ID == %ld", (long) ignoredID.longValue]];
            if (threadsWithIgnoredID.count) {
                NSMutableArray *mutableThreads = threads.mutableCopy;
                [mutableThreads removeObjectsInArray:threadsWithIgnoredID];
                threads = mutableThreads;
            }
        }
        ContentPage *page = [[ContentPage alloc] init];
        page.threads = threads;
        page.pageNumber = downloader.pageNumber;
        page.forum = self.forum;
        if (self.threads.lastObject.pageNumber == downloader.pageNumber) {
            [self.threads removeLastObject];
        }
        if (self.pageNumber < downloader.pageNumber) {
            [self.threads addObject:page];
        } else {
            [self.threads insertObject:page atIndex:0];
        }
        self.lastBatchOfThreads = threads;
        self.pageNumber = downloader.pageNumber;
    }
    // Sort by page number.
    [self.threads sortUsingComparator:^NSComparisonResult(ContentPage * _Nonnull page1, ContentPage * _Nonnull page2) {
        return page1.pageNumber < page2.pageNumber ? NSOrderedAscending : NSOrderedDescending;
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        // If the downloader is a massive thread downloader, don't inform delegate about thread download completed event, because there could be more such events.
        if ([downloader isKindOfClass:[czzMassiveThreadDownloader class]]) {
            // For massive downloader, if the result is success but no new thread has been added, consider this as a failure.
            if (success && previousThreadCount == self.threads.count) {
                DLog(@"Massive downloader provided no new content, stopping...");
                [self stopAllOperation];
                if ([self.delegate respondsToSelector:@selector(homeViewManager:threadContentProcessed:newThreads:allThreads:)]) {
                    [self.delegate homeViewManager:self
                            threadContentProcessed:false
                                        newThreads:self.lastBatchOfThreads
                                        allThreads:self.threads];
                }
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(homeViewManager:threadContentProcessed:newThreads:allThreads:)]) {
                [self.delegate homeViewManager:self
                        threadContentProcessed:success
                                    newThreads:self.lastBatchOfThreads
                                    allThreads:self.threads];
            }
        }
    });
}

- (void)massiveDownloaderUpdated:(czzMassiveThreadDownloader *)downloader {
    // At the moment, the downloading is not finished yet.
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(viewManagerContinousDownloadUpdated:)]) {
            [self.delegate viewManagerContinousDownloadUpdated:self];
        }
    });
}

- (void)massiveDownloader:(czzMassiveThreadDownloader *)downloader success:(BOOL)success downloadedThreads:(NSArray *)threads errors:(NSArray *)errors {
    DLog(@"");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(viewManager:continousDownloadCompleted:)]) {
            [self.delegate viewManager:self continousDownloadCompleted:success];
        }
    });
}

#pragma mark - content managements.
- (void)reset {
    self.pageNumber = 1;
    self.pageNumberChanged = NO;
    self.loadingMode = ViewManagerLoadingModeNormal;
}

-(void)removeAll {
    self.pageNumber = 1;
    // Clear all.
    self.lastBatchOfThreads = self.threads = nil;
}

- (void)refresh {
    [self reset];
    [super refresh];
}

- (void)loadPreviousPage {
    if (self.threads.count >= 2 && self.threads[1].pageNumber > 1) {
        [self loadMoreThreads:self.threads[1].pageNumber - 1];
    } else {
        [self refresh];
    }
}

- (void)loadAll {
    DLog(@"");
    [self stopAllOperation];
    self.massiveDownloader = [[czzMassiveThreadDownloader alloc] initWithForum:self.downloader.parentForum
                                                                     andThread:self.downloader.parentThread];
    self.massiveDownloader.delegate = self;
    self.massiveDownloader.pageNumber = self.threads.lastObject.pageNumber + 1; // Start from the next page.
    [self.massiveDownloader start];
}

- (void)stopAllOperation {
    DLog(@"Should stop all downloading operation.");
    if (self.massiveDownloader) {
        [self.massiveDownloader stop];
    }
    if (self.downloader) {
        [self.downloader stop];
    }
}

- (void)setOnlyShowUserID:(NSString *)userID {
    [self.threads enumerateObjectsUsingBlock:^(ContentPage * _Nonnull page, NSUInteger idx, BOOL * _Nonnull stop) {
        page.showOnlyUserID = userID;
    }];
}

- (void)loadMoreThreads {
    if (self.threads.lastObject.realThreadCount >= settingCentre.response_per_page) {
        [self loadMoreThreads:self.threads.lastObject.pageNumber + 1];
    } else {
        [self loadMoreThreads:self.threads.lastObject.pageNumber];
    }
}

- (void)loadMoreThreads:(NSInteger)pageNumber {
    self.previousPageNumber = self.pageNumber;
    [super loadMoreThreads:pageNumber];
    // If the updated page number is different than the old page number, set self.pageIncreased to true.
    self.pageNumberChanged = self.pageNumber != self.previousPageNumber;
}

- (void)jumpToPage:(NSInteger)page {
    [self stopAllOperation];
    [self removeAll];
    self.threads = nil;
    self.loadingMode = ViewManagerLoadingModeJumpping;
    [self loadMoreThreads:page];
}

// Override to support return self
+ (instancetype)sharedManager
{
    [NSException raise:@"NOT SUPPORTED" format:@"This class should not be a singleton: %@", NSStringFromClass([self class])];
    return nil;
}

#pragma mark - Getters

- (NSMutableArray<ContentPage *> *)threads {
    if (!_threads) {
        _threads = [[NSMutableArray alloc] init];
        // Parent thread would be hosted in its own section.
        ContentPage *page = [[ContentPage alloc] init];
        page.threads = @[self.parentThread];
        page.pageNumber = 0;
        page.forum = self.forum;
        [_threads addObject:page];
    }
    return _threads;
}

- (NSInteger)totalPages {
    CGFloat totalPages = (CGFloat)self.parentThread.responseCount / (CGFloat)settingCentre.response_per_page;
    return ceilf(totalPages);
}

- (NSString *)pageNumberKey {
    return [kRecordedPageNumberKeyPrefix stringByAppendingString:[self recordedPageIdentifier]];
}

// Identifies a thread for page recording. The host is part of the identity, so
// switching between AC and BT keeps separate positions. The separator matters:
// the old key concatenated host and thread ID with nothing in between, which made
// "http://host/12" + "3" and "http://host/1" + "23" the same key.
- (NSString *)recordedPageIdentifier {
    NSString *host = settingCentre.activeHost;
    if (!host.length) {
        host = settingCentre.userDefActiveHost == SettingsHostBT
            ? settingCentre.bt_isle_host
            : settingCentre.ac_isle_host;
    }
    return [NSString stringWithFormat:@"%@|%ld", host ?: @"", (long)self.parentThread.ID];
}

- (NSString *)baseURLString {
    return [[settingCentre thread_content_host] stringByReplacingOccurrencesOfString:kParentID withString:self.parentID];
}

- (czzThreadDownloader *)downloader {
    if (!_downloader) {
        _downloader = [[czzThreadDownloader alloc] initWithForum:self.forum andThread:self.parentThread];
    }
    _downloader.parentForum = self.forum;
    _downloader.parentThread = self.parentThread;
    _downloader.delegate = self;
    return _downloader;
}

// Override isDownloading, this class need to consider the massive downloader as well.
- (BOOL)isDownloading {
    BOOL massiveDownloading = self.massiveDownloader.isDownloading;
    BOOL normalDownloading = super.isDownloading;
    return normalDownloading || massiveDownloading;
}

- (BOOL)isMassiveDownloading {
    return self.massiveDownloader.isDownloading;
}

@end
