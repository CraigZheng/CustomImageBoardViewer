//
//  czzPostSender.h
//  CustomImageBoardViewer
//
//  Created by Craig on 6/10/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzForum.h"

@protocol czzPostSenderDelegate <NSObject>
@optional
-(void)postSenderProgressUpdated:(CGFloat)percent;
-(void)statusReceived:(BOOL)status message:(NSString*)message;
@end
@interface czzPostSender : NSObject
@property (nonatomic) NSURL *targetURL;
@property id<czzPostSenderDelegate> delegate;
//@property (nonatomic) NSString *forumName;
@property (nonatomic) czzForum *forum;
@property (nonatomic) NSString *forumID;
@property (nonatomic) NSInteger parentID;
//for czzPost object
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *email;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *content;
@property (nonatomic) NSData *imgData;

-(void)sendPost;
@end
