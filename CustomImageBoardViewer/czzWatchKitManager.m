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
#import "czzThreadViewModelManager.h"
#import "czzForumManager.h"

@interface czzWatchKitManager () <czzHomeViewModelManagerDelegate>
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (strong, nonatomic) czzHomeViewModelManager *homeViewModelManager;
@property (strong, nonatomic) czzThreadViewModelManager *threadViewModelManager;
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
    id command = [userInfo objectForKey:watchKitCommandKey];

    BOOL loadMore = [[userInfo objectForKey:watchKitCommandLoadMore] boolValue];
    if ([command isEqual: @(watchKitCommandLoadHomeView)]) {
        czzWKForum *forum = [[czzWKForum alloc] initWithDictionary:[userInfo objectForKey:watchKitCommandForumKey]];
        [self watchKitLoadHomeView:forum loadMore:loadMore];
    } else if ([command isEqual:@(watchKitCommandLoadThreadView)]) {
        czzWKThread *selectedThread = [[czzWKThread alloc] initWithDictionary:[userInfo objectForKey:@"THREAD"]];
        if (selectedThread) {
            [self watchKitLoadThreadView:selectedThread loadMore:loadMore];
        }
    } else if ([command isEqual:@(watchKitCommandLoadForumView)]) {
        [self watchKitLoadForumView];
    } else if ([command isEqual:@(watchKitCommandLoadImage)]) {
        NSString *imgURL = [userInfo objectForKey:watchKitCommandImageKey];
        [self watchkitLoadImage:imgURL];
    }
}

-(void)watchkitLoadImage:(NSString*)imgURL {
    NSString *targetImgURL;
    if ([imgURL hasPrefix:@"http"])
        targetImgURL = imgURL;
    else
        targetImgURL = [[settingCentre thumbnail_host] stringByAppendingPathComponent:imgURL];

    [[czzImageCentre sharedInstance] downloadThumbnailWithURL:imgURL isCompletedURL:YES];
    
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
    
    self.homeViewModelManager = [czzHomeViewModelManager sharedManager];
    
    czzForum *selectedForum = [czzForum new];
    selectedForum.name = forum.name;
    [self.homeViewModelManager setForum:selectedForum];
    
    __block NSMutableDictionary *replyDictionary = [NSMutableDictionary new];
    __weak typeof (self) weakSelf = self;
    self.homeViewModelManager.watchKitCompletionHandler = ^(BOOL success, NSArray *threads) {
        if (success) {
            //TODO: if success? if fail?
        }
        [replyDictionary addEntriesFromDictionary:@{@(watchKitMiscInfoScreenTitleHome) : weakSelf.homeViewModelManager.forum.name.length ? [NSString stringWithFormat:@"%@-%ld", weakSelf.homeViewModelManager.forum.name, (long)weakSelf.homeViewModelManager.pageNumber] : @"没有板块"}];
        [replyDictionary addEntriesFromDictionary:@{@(watchKitCommandLoadHomeView) : [weakSelf watchKitThreadsWithThreads:threads]}];
        [weakSelf replyWithDictionary:replyDictionary];
    };
    if (loadMore && self.homeViewModelManager.threads.count) {
        [self.homeViewModelManager loadMoreThreads];
    } else {
        [self.homeViewModelManager refresh];
    }
}

-(void)watchKitLoadThreadView:(czzWKThread*)selectedThread loadMore:(BOOL)loadMore {
    [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]];
    
    czzThread *parentThread = [[czzThread alloc] initWithThreadID:selectedThread.ID];
    self.threadViewModelManager = [[czzThreadViewModelManager alloc] initWithParentThread:parentThread andForum:nil];
    
    [self.threadViewModelManager restorePreviousState];
    __weak typeof (self.threadViewModelManager) weakThreadViewModelManager = self.threadViewModelManager;
    __weak typeof (self) weakSelf = self;
    self.threadViewModelManager.watchKitCompletionHandler = ^(BOOL success, NSArray *threads) {
        NSDictionary *replyDictionary = @{@(watchKitCommandLoadThreadView) : [weakSelf watchKitThreadsWithThreads:weakThreadViewModelManager.threads]};
        [weakSelf replyWithDictionary:replyDictionary];
    };
    
    if (loadMore && self.threadViewModelManager.threads.count > 1) {
        [self.threadViewModelManager loadMoreThreads];
    } else {
        [self.threadViewModelManager refresh];
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
