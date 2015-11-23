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
@property (strong, nonatomic) czzThreadViewManager *threadViewManager;
@property (strong, nonatomic) NSString *requestedImageURL;
@property (strong, nonatomic) NSMutableSet *requestedThreadDownloaders;
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
    
    czzWatchKitCommand *command = [[czzWatchKitCommand alloc] initWithDictionary:userInfo];
    if (command) {
        switch (command.action) {
            case watchKitCommandLoadForumView:
                [self loadWKForumsWithCommand:command replyHandler:reply];
                break;
            case watchKitCommandLoadHomeView:
                [self loadHomeWithCommand:command loadMore:NO replyHandler:reply];
                break;
            default:
                // Reply an empty dictionary to indicate error.
                reply([NSDictionary new]);
                break;
        }
    }
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

-(void)loadWKForumsWithCommand:(czzWatchKitCommand *)command replyHandler:(void(^)(NSDictionary *responseMessage))replyHandler {
    [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]];

    // Update the forums if necessary
    if ([czzForumManager sharedManager].forums.count > 0) {
        NSMutableArray *forums = [NSMutableArray new];
        for (czzForum *forum in [[czzForumManager sharedManager] forums]) {
            [forums addObject: [[forum watchKitForum] encodeToDictionary]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            replyHandler(@{command.caller : forums});
        });
    } else {
        [[czzForumManager sharedManager] updateForums:^(BOOL success, NSError *error) {
            NSMutableArray *forums = [NSMutableArray new];
            for (czzForum *forum in [[czzForumManager sharedManager] forums]) {
                [forums addObject: [[forum watchKitForum] encodeToDictionary]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                replyHandler(@{command.caller : forums});
            });
        }];
    }
}

-(void)loadHomeWithCommand:(czzWatchKitCommand *)command loadMore:(BOOL)loadMore replyHandler:(void(^)(NSDictionary *responseMessage))replyHandler {
    [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]];
    // Get czzForum object from the incoming czzWKForum object.
    czzWKForum *selectedForum = [[czzWKForum alloc] initWithDictionary:[command.parameter valueForKey:@"FORUM"]];
    czzForum *tempForum = [czzForum new];
    tempForum.name = selectedForum.name;
    czzThreadDownloader *threadDownloader = [[czzThreadDownloader alloc] initWithForum:tempForum];
    __weak id weakRefDownloader = threadDownloader;
    // Add the newly created downloader object to self.requestedThreadDownloader set.
    [self.requestedThreadDownloaders addObject:threadDownloader];
    __weak typeof (self) weakSelf = self;
    threadDownloader.completionHandler = ^(BOOL success, NSArray *threads, NSError *error) {
        DLog(@"%s : %ld threads : %@", __PRETTY_FUNCTION__, threads.count, error);
        replyHandler(@{command.caller : [weakSelf watchKitThreadsWithThreads:threads]});
        if (weakRefDownloader) {
            [self.requestedThreadDownloaders removeObject:weakRefDownloader];
        }
    };
    dispatch_async(dispatch_get_main_queue(), ^{
        [threadDownloader start];
    });
    
//    __block NSMutableDictionary *replyDictionary = [NSMutableDictionary new];
//#warning COME BACK LATER
//    self.homeViewManager.watchKitCompletionHandler = ^(BOOL success, NSArray *threads) {
//        if (success) {
//            //TODO: if success? if fail?
//        }
//        [replyDictionary addEntriesFromDictionary:@{@(watchKitMiscInfoScreenTitleHome) : weakSelf.homeViewManager.forum.name.length ? [NSString stringWithFormat:@"%@-%ld", weakSelf.homeViewManager.forum.name, (long)weakSelf.homeViewManager.pageNumber] : @"没有板块"}];
//        [replyDictionary addEntriesFromDictionary:@{@(watchKitCommandLoadHomeView) : [weakSelf watchKitThreadsWithThreads:threads]}];
//        [weakSelf replyWithDictionary:replyDictionary];
//    };
//    if (loadMore && self.homeViewManager.threads.count) {
//        [self.homeViewManager loadMoreThreads];
//    } else {
//        [self.homeViewManager refresh];
//    }
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

#warning NEEDS UPDATING
//-(void)replyWithDictionary:(NSDictionary *)dict {
//    [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"Passing %ld objects to watch kit...", (long)dict.allValues.count]];
//
//    if (self.reply) {
//        self.reply(dict);
//        self.reply = nil;
//    }
//    [self endBackgroundTask];
//}

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
    
    return wkThreads;
}

#pragma mark - Getter

- (NSMutableSet *)requestedThreadDownloaders {
    if (!_requestedThreadDownloaders) {
        _requestedThreadDownloaders = [NSMutableSet new];
    }
    return _requestedThreadDownloaders;
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
