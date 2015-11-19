//
//  czzWatchKitManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 18/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWatchKitManager.h"
#import "czzWatchKitCommand.h"
#import "czzWKForum.h"
#import "czzThreadViewManager.h"
#import "czzImageDownloaderManager.h"
#import "czzForumManager.h"

@interface czzWatchKitManager () <czzHomeViewManagerDelegate>
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (strong, nonatomic) czzHomeViewManager *homeViewManager;
@property (strong, nonatomic) czzThreadViewManager *threadViewManager;
@property (strong, nonatomic) NSString *requestedImageURL;

@property (copy)void (^reply)(NSDictionary *replyDictionary);
@end

@implementation czzWatchKitManager

-(instancetype)init {
    self = [super init];
    if (self) {
//        [[NSNotificationCenter defaultCenter] addObserver:THUMBNAIL_DOWNLOADED_NOTIFICATION selector:@selector(handleThumbnailDownloaded:) name:THUMBNAIL_DOWNLOADED_NOTIFICATION object:nil];
    }
    
    return self;
}

-(void)handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply withBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier{
    self.backgroundTaskIdentifier = backgroundTaskIdentifier;
    self.reply = reply;
    
#warning DEBUG
    czzWatchKitCommand *command = [[czzWatchKitCommand alloc] initWithDictionary:userInfo];
    command.caller = NSStringFromClass(self.class);
    reply(command.encodeToDictionary);
//    id command = [userInfo objectForKey:watchKitCommandKey];
//
//    BOOL loadMore = [[userInfo objectForKey:watchKitCommandLoadMore] boolValue];
//    if ([command isEqual: @(watchKitCommandLoadHomeView)]) {
//        czzWKForum *forum = [[czzWKForum alloc] initWithDictionary:[userInfo objectForKey:watchKitCommandForumKey]];
//        [self watchKitLoadHomeView:forum loadMore:loadMore];
//    } else if ([command isEqual:@(watchKitCommandLoadThreadView)]) {
//        czzWKThread *selectedThread = [[czzWKThread alloc] initWithDictionary:[userInfo objectForKey:@"THREAD"]];
//        if (selectedThread) {
//            [self watchKitLoadThreadView:selectedThread loadMore:loadMore];
//        }
//    } else if ([command isEqual:@(watchKitCommandLoadForumView)]) {
//        [self watchKitLoadForumView];
//    } else if ([command isEqual:@(watchKitCommandLoadImage)]) {
//        NSString *imgURL = [userInfo objectForKey:watchKitCommandImageKey];
//        [self watchkitLoadImage:imgURL];
//    }
}

-(void)watchkitLoadImage:(NSString*)imgURL {
    NSString *targetImgURL;
    if ([imgURL hasPrefix:@"http"])
        targetImgURL = imgURL;
    else
        targetImgURL = [[settingCentre thumbnail_host] stringByAppendingPathComponent:imgURL];
    [[czzImageDownloaderManager sharedManager] downloadImageWithURL:imgURL isThumbnail:NO];
//    [[czzImageCacheManager sharedInstance] downloadThumbnailWithURL:imgURL isCompletedURL:YES];
    
}

-(void)watchKitLoadForumView {
    [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]];

    [[czzForumManager sharedManager] updateForums:^(BOOL success, NSError *error) {
        NSMutableArray *forums = [NSMutableArray new];
        for (czzForum *forum in [[czzForumManager sharedManager] forums]) {
            [forums addObject: [[forum watchKitForum] encodeToDictionary]];
        }
        [self replyWithDictionary:@{@(watchKitCommandLoadForumView) : forums}];
    }];
}

-(void)watchKitLoadHomeView:(czzWKForum*)forum loadMore:(BOOL)loadMore {
    [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]];
    
    self.homeViewManager = [czzHomeViewManager new];
    
    czzForum *selectedForum = [czzForum new];
    selectedForum.name = forum.name;
    [self.homeViewManager setForum:selectedForum];
    
    __block NSMutableDictionary *replyDictionary = [NSMutableDictionary new];
    __weak typeof (self) weakSelf = self;
#warning COME BACK LATER
//    self.homeViewManager.watchKitCompletionHandler = ^(BOOL success, NSArray *threads) {
//        if (success) {
//            //TODO: if success? if fail?
//        }
//        [replyDictionary addEntriesFromDictionary:@{@(watchKitMiscInfoScreenTitleHome) : weakSelf.homeViewManager.forum.name.length ? [NSString stringWithFormat:@"%@-%ld", weakSelf.homeViewManager.forum.name, (long)weakSelf.homeViewManager.pageNumber] : @"没有板块"}];
//        [replyDictionary addEntriesFromDictionary:@{@(watchKitCommandLoadHomeView) : [weakSelf watchKitThreadsWithThreads:threads]}];
//        [weakSelf replyWithDictionary:replyDictionary];
//    };
    if (loadMore && self.homeViewManager.threads.count) {
        [self.homeViewManager loadMoreThreads];
    } else {
        [self.homeViewManager refresh];
    }
}

-(void)watchKitLoadThreadView:(czzWKThread*)selectedThread loadMore:(BOOL)loadMore {
    [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]];
    
    czzThread *parentThread = [[czzThread alloc] initWithThreadID:selectedThread.ID];
    self.threadViewManager = [[czzThreadViewManager alloc] initWithParentThread:parentThread andForum:nil];
    
    [self.threadViewManager restorePreviousState];
    __weak typeof (self.threadViewManager) weakthreadViewManager = self.threadViewManager;
    __weak typeof (self) weakSelf = self;
#warning COME BACK LATER
//    self.threadViewManager.watchKitCompletionHandler = ^(BOOL success, NSArray *threads) {
//        NSDictionary *replyDictionary = @{@(watchKitCommandLoadThreadView) : [weakSelf watchKitThreadsWithThreads:weakthreadViewManager.threads]};
//        [weakSelf replyWithDictionary:replyDictionary];
//    };
    
    if (loadMore && self.threadViewManager.threads.count > 1) {
        [self.threadViewManager loadMoreThreads];
    } else {
        [self.threadViewManager refresh];
    }
}

-(void)replyWithDictionary:(NSDictionary *)dict {
    [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"Passing %ld objects to watch kit...", (long)dict.allValues.count]];

    if (self.reply) {
        self.reply(dict);
        self.reply = nil;
    }
    [self endBackgroundTask];
}

-(void)endBackgroundTask {
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        }
    }];
}

#pragma mark - Thumbnail downloaded notification 
-(void)handleThumbnailDownloaded:(NSNotification*)notification {
//    NSString *downloadedImageName = [[notification.userInfo objectForKey:@"FilePath"] lastPathComponent];
//    
//    if ([self.requestedImageURL.lastPathComponent isEqualToString:downloadedImageName]) {
//        NSDictionary *imgReply =
//    }
}

-(NSArray *)watchKitThreadsWithThreads:(NSArray *)threads {
    NSMutableArray *wkThreads = [NSMutableArray new];
    for (czzThread* thread in threads) {
        [wkThreads addObject:[[thread watchKitThread] encodeToDictionary]];
    }
    
#ifdef DEBUG
    // Load from cache
    NSString *wkThreadCache = [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:@"wkCaches.dat"];
    if (!wkThreads.count) {
        wkThreads = [NSKeyedUnarchiver unarchiveObjectWithFile:wkThreadCache];
    } else {
        [NSKeyedArchiver archiveRootObject:wkThreads toFile:wkThreadCache];
    }
    
    
#endif

    return wkThreads;
}

+(instancetype)sharedManager {
    static dispatch_once_t once_token;
    static id sharedManager;
    if (!sharedManager) {
        dispatch_once(&once_token, ^{
            sharedManager = [czzWatchKitManager new];
        });
    }
    return sharedManager;
}

@end
