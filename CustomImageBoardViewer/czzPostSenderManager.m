//
//  czzPostSenderManager.m
//  CustomImageBoardViewer
//
//  Created by Craig on 22/02/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzPostSenderManager.h"

#import "czzPostSender.h"
#import "czzBannerNotificationUtil.h"
#import "czzHistoryManager.h"
#import "czzThreadDownloader.h"
#import "czzWeakReferenceDelegate.h"

@interface czzPostSenderManager() <czzPostSenderDelegate>
@property (nonatomic, strong) NSMutableOrderedSet *postSenders;
@property (nonatomic, strong) NSMutableOrderedSet *delegates;
@property (strong, nonatomic) czzThreadDownloader *threadDownloader;

@end

@implementation czzPostSenderManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _postSenders = [NSMutableOrderedSet new];
    }
    return self;
}

- (void)firePostSender:(czzPostSender *)postSender {
    // Remove the previous failed post sender.
    self.lastFailedPostSender = nil;
    if (postSender) {
        [self.postSenders addObject:postSender];
        postSender.delegate = self;
        [postSender sendPost];
        // Inform delegate that a postint process has been started.
        [self iterateDelegatesWithBlock:^(id<czzPostSenderManagerDelegate> delegate) {
            if ([delegate respondsToSelector:@selector(postSenderManager:startPostingForSender:)]) {
                [delegate postSenderManager:self startPostingForSender:postSender];
            }
        }];
    }
}

#pragma mark - Getters

- (czzPostSender *)lastPostSender {
    return self.postSenders.lastObject;
}

-(NSMutableOrderedSet *)delegates {
    if (!_delegates) {
        _delegates = [NSMutableOrderedSet new];
    }
    // Loop through all delegate objects in delegates, and remove those that are invalid.
    NSMutableArray *delegatesToRemove = [NSMutableArray new];
    for (czzWeakReferenceDelegate * weakRefDelegate in _delegates) {
        if (!weakRefDelegate.isValid) {
            [delegatesToRemove addObject:weakRefDelegate];
        }
    }
    [_delegates removeObjectsInArray:delegatesToRemove];
    return _delegates;
}

#pragma mark - Delegates management
-(void)addDelegate:(id<czzPostSenderManagerDelegate>)delegate {
    [self.delegates addObject:[czzWeakReferenceDelegate weakReferenceDelegate:delegate]];
}

-(void)removeDelegate:(id<czzPostSenderManagerDelegate>)delegate {
    [self.delegates removeObject:delegate];
}

-(void)iterateDelegatesWithBlock:(void(^)(id<czzPostSenderManagerDelegate> delegate))block {
    for (czzWeakReferenceDelegate* weakRefDelegate in [self.delegates copy]) {
        id<czzPostSenderManagerDelegate> delegate = weakRefDelegate.delegate;
        block(delegate);
    }
}

-(BOOL)hasDelegate:(id<czzPostSenderManagerDelegate>)delegate {
    return [self.delegates containsObject:delegate];
}

#pragma mark - czzPostSenderDelegate

- (void)postSender:(czzPostSender *)postSender completedPosting:(BOOL)successful message:(NSString *)message {
    DLog(@"");
    if (successful) {
        // Remove the last failed post sender.
        self.lastFailedPostSender = nil;
        // Add the just replied thread to watchlist manager.
        if (postSender.parentThread) {
            [historyManager addToRespondedList:postSender.parentThread];
        } else if (postSender.forum) {
            [self recordThreadPostedWithTitle:postSender.title
                                      content:postSender.content
                                     hasImage:postSender.imgData != nil
                                        forum:postSender.forum];
        }
    } else {
        // Keep record of the last failed post sender.
        self.lastFailedPostSender = postSender;
    }
    // Inform all delegates that a post sender is completed.
    [self iterateDelegatesWithBlock:^(id<czzPostSenderManagerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(postSenderManager:postingCompletedForSender:success:message:)]) {
            [delegate postSenderManager:self
              postingCompletedForSender:postSender
                                success:successful
                                message:message];
        }
    }];
    // Remove the completed post sender from self.postSenders.
    [self.postSenders removeObject:postSender];
}

- (void)postSender:(czzPostSender *)postSender progressUpdated:(CGFloat)percent {
    [self iterateDelegatesWithBlock:^(id<czzPostSenderManagerDelegate> delegate) {
        if ([delegate respondsToSelector:@selector(postSenderManager:postSender:progressUpdated:)]) {
            [delegate postSenderManager:self
                             postSender:delegate
                        progressUpdated:percent];
        }
    }];
}

#pragma mark - Refresh content, and record history.

- (void)recordThreadPostedWithTitle:(NSString*)title
                            content:(NSString*)content
                           hasImage:(BOOL)hasImage
                              forum:(czzForum*)forum {

    self.threadDownloader = [czzThreadDownloader new];
    self.threadDownloader.pageNumber = 1;
    self.threadDownloader.parentForum = forum;
    
    // In completion handler, compare the downloaded threads and see if there's any that is matching.
    DLog(@"%@", content);
    self.threadDownloader.completionHandler = ^(BOOL success, NSArray *downloadedThreads, NSError *error){
        DLog(@"%s, error: %@", __PRETTY_FUNCTION__, error);
        for (czzThread *thread in downloadedThreads) {
            // Compare title and content.
            czzThread *matchedThread;
            DLog(@"Downloaded thread: %@", thread.content.string);
            // When comparing, remove the white space and newlines from both the reference title/content and the thread title content,
            // this would reduce the risk of error.
            if (title.length && [[title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                 isEqualToString:[thread.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]) {
                matchedThread = thread;
            } else if (content.length && [[content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                          isEqualToString:[thread.content.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]) {
                matchedThread = thread;
            }
            // If no title and content given, but has image, then the first downloaded thread with image is most likely the matching thread.
            else if (hasImage && thread.imgSrc.length) {
                matchedThread = thread;
            }
            if (matchedThread) {
                DDLogDebug(@"Found match: %@", matchedThread);
                [historyManager addToPostedList:matchedThread];
                break;
            }
        }
    };
    // Start the refreshing a few seconds later, give server some time to respond.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.threadDownloader start];
    });


}

+ (instancetype)sharedManager {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [czzPostSenderManager new];
    });
    return sharedInstance;
}

@end
