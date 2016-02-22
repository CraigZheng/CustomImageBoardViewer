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

@interface czzPostSenderManager() <czzPostSenderDelegate>
@property (nonatomic, strong) NSMutableOrderedSet *postSenders;
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
    }
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
    // Remove the completed post sender from self.postSenders.
    [self.postSenders removeObject:postSender];
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
