//
//  czzReplyUtil.h
//  CustomImageBoardViewer
//
//  Created by Craig on 15/01/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class czzThread, czzForum;
@interface czzReplyUtil : NSObject

+ (void)postToForum:(czzForum *)forum;
+ (void)replyToThread:(czzThread *)thread inParentThread:(czzThread *)parentThread;
+ (void)replyMainThread:(czzThread *)thread;
+ (void)reportThread:(czzThread *)selectedThread inParentThread:(czzThread *)parentThread;

@end
