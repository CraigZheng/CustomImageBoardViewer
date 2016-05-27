//
//  czzPostSender.h
//  CustomImageBoardViewer
//
//  Created by Craig on 6/10/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzForum.h"
#import "czzThread.h"

typedef NS_ENUM(NSInteger, postSenderMode) {
    postSenderModeUnknown = 0,
    postSenderModeNew,
    postSenderModeReply
};

@class czzPostSender;
@protocol czzPostSenderDelegate <NSObject>
@optional
-(void)postSender:(czzPostSender *)postSender progressUpdated:(CGFloat)percent;
-(void)postSender:(czzPostSender *)postSender completedPosting:(BOOL)successful message:(NSString*)message response:(NSString*)response;
@end
@interface czzPostSender : NSObject
@property (nonatomic) NSURL *targetURL;
@property (weak, nonatomic) id<czzPostSenderDelegate> delegate;
//@property (nonatomic) NSString *forumName;
@property (nonatomic) czzForum *forum;
@property (nonatomic) NSString *forumID;
@property (nonatomic) czzThread *parentThread;
//for czzPost object
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *email;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *content;
@property (readonly) NSData *imgData;

@property (nonatomic) postSenderMode postMode;

- (void)setImgData:(NSData *)imgData format:(NSString*)format;
- (void)sendPost;
@end
