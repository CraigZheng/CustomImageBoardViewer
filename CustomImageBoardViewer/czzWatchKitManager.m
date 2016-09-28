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
#import "czzWatchListManager.h"
#import "czzForumManager.h"
#import <WatchConnectivity/WatchConnectivity.h>

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
            case watchKitCommandLoadThreadView:
                [self loadThreadWithCommand:command replyHandler:reply];
                break;
            case watchKitCommandWatchThread:
                [self watchThreadWithCommand:command replyHandler:reply];
                break;
            default:
                // Reply an empty dictionary to indicate error.
                reply([NSDictionary new]);
                break;
        }
    }
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
    // Update the forums if necessary
    if ([czzForumManager sharedManager].forums.count > 0) {
        NSMutableArray *forums = [NSMutableArray new];
        for (czzForum *forum in [[czzForumManager sharedManager] forums]) {
            [forums addObject: [[forum watchKitForum] encodeToDictionary]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
//            replyHandler(@{command.caller : forums});
            [[WCSession defaultSession] updateApplicationContext:@{command.caller : forums} error:nil];
        });
    } else {
        [[czzForumManager sharedManager] updateForums:^(BOOL success, NSError *error) {
            NSMutableArray *forums = [NSMutableArray new];
            for (czzForum *forum in [[czzForumManager sharedManager] forums]) {
                [forums addObject: [[forum watchKitForum] encodeToDictionary]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
//                replyHandler(@{command.caller : forums});
                [[WCSession defaultSession] updateApplicationContext:@{command.caller : forums} error:nil];
            });
        }];
    }
}

-(void)loadHomeWithCommand:(czzWatchKitCommand *)command loadMore:(BOOL)loadMore replyHandler:(void(^)(NSDictionary *responseMessage))replyHandler {
    // Get czzForum object from the incoming czzWKForum object.
    czzWKForum *selectedForum = [[czzWKForum alloc] initWithDictionary:[command.parameter valueForKey:@"FORUM"]];
    czzForum *tempForum = [czzForum new];
    tempForum.name = selectedForum.name;
    tempForum.forumID = selectedForum.forumID;
    czzThreadDownloader *threadDownloader = [[czzThreadDownloader alloc] initWithForum:tempForum];
    __weak id weakRefDownloader = threadDownloader;
    // Add the newly created downloader object to self.requestedThreadDownloader set.
    [self.requestedThreadDownloaders addObject:threadDownloader];
    __weak typeof (self) weakSelf = self;
    threadDownloader.completionHandler = ^(BOOL success, NSArray *threads, NSError *error) {
        DDLogDebug(@"%s : %ld threads : %@", __PRETTY_FUNCTION__, threads.count, error);
//        replyHandler(@{command.caller : [weakSelf watchKitThreadsWithThreads:threads]});
        [[WCSession defaultSession] updateApplicationContext:@{command.caller : [weakSelf watchKitThreadsWithThreads:threads]} error:nil];
        if (weakRefDownloader) {
            [self.requestedThreadDownloaders removeObject:weakRefDownloader];
        }
    };
    dispatch_async(dispatch_get_main_queue(), ^{
        [threadDownloader start];
    });
}

-(void)loadThreadWithCommand:(czzWatchKitCommand *)command replyHandler:(void(^)(NSDictionary *responseMessage))replyHandler {
    // Get czzThread from czzWKThread
    czzWKThread *tempWKThread = [[czzWKThread alloc] initWithDictionary:[command.parameter objectForKey:@"THREAD"]];
    czzThread *selectedThread = [self fatThreadWithWKThread:tempWKThread];
    // Get requested page
    NSNumber *pageNumber = [command.parameter objectForKey:@"PAGE"];
    // Construct and start the thread downloader.
    czzThreadDownloader *threadDownloader = [[czzThreadDownloader alloc] initWithForum:nil andThread:selectedThread];
    threadDownloader.pageNumber = pageNumber.integerValue;
    [self.requestedThreadDownloaders addObject:threadDownloader];
    __weak typeof (self) weakSelf = self;
    __weak typeof(threadDownloader) weakRefThreadDownloader = threadDownloader;

    threadDownloader.completionHandler = ^(BOOL success, NSArray *threads, NSError *error){
        NSDictionary *replyDictionary = @{command.caller : [weakSelf watchKitThreadsWithThreads:threads]};
//        replyHandler(replyDictionary);
        [[WCSession defaultSession] updateApplicationContext:replyDictionary error:nil];
        if (weakRefThreadDownloader) {
            [weakSelf.requestedThreadDownloaders removeObject:weakRefThreadDownloader];
        }
    };
    dispatch_async(dispatch_get_main_queue(), ^{
        [threadDownloader start];
    });
}

- (void)watchThreadWithCommand:(czzWatchKitCommand *)command replyHandler:(void(^)(NSDictionary *responseMessage))replyHandler {
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);
    czzWKThread *tempWKThread = [[czzWKThread alloc] initWithDictionary:command.parameter[@"THREAD"]];
    czzThread *selectedThread = [self fatThreadWithWKThread:tempWKThread];
    DDLogDebug(@"should watch: %@", tempWKThread);
    //TODO: a proper response.
    replyHandler([NSDictionary new]);
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

#pragma mark - Util methods

-(NSArray *)watchKitThreadsWithThreads:(NSArray *)threads {
    NSMutableArray *wkThreads = [NSMutableArray new];
    for (czzThread* thread in threads) {
        [wkThreads addObject:[[thread watchKitThread] encodeToDictionary]];
    }
    
    return wkThreads;
}

- (czzThread *)fatThreadWithWKThread:(czzWKThread *)wkThread {
    czzThread *thread = [czzThread new];
    thread.ID = wkThread.ID;
    thread.title = wkThread.title;
    thread.name = wkThread.name;
    thread.content = [[NSAttributedString alloc] initWithString:wkThread.content];
    thread.postDateTime = wkThread.postDate;
    thread.thImgSrc = wkThread.thumbnailFile;
    thread.imgSrc = wkThread.imageFile;
    
    return thread;
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
