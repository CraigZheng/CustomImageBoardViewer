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
#import "czzWeakReferenceDelegate.h"

@interface czzPostSenderManager() <czzPostSenderDelegate>
@property (nonatomic, strong) NSMutableOrderedSet *postSenders;
@property (nonatomic, strong) NSMutableOrderedSet *delegates;
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
        [czzBannerNotificationUtil displayMessage:@"提交成功"
                                         position:BannerNotificationPositionTop];
        // Add the just replied thread to watchlist manager.
        if (postSender.parentThread) {
            [historyManager addToRespondedList:postSender.parentThread];
        } else if (postSender.forum) {
            // Post sent to forum, try to locate the just posted thread.
            [historyManager addToPostedList:postSender.title
                                    content:postSender.content
                                   hasImage:postSender.imgData != nil
                                      forum:postSender.forum];
        }
    } else {
        [czzBannerNotificationUtil displayMessage:message.length ? message : @"出错啦"
                                         position:BannerNotificationPositionTop];
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

+ (instancetype)sharedManager {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [czzPostSenderManager new];
    });
    return sharedInstance;
}

@end
