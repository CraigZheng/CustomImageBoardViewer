//
//  czzReply.h
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzForum.h"
#import "czzThread.h"
@interface czzPost : NSObject
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *content;
@property (strong, nonatomic) NSString *access_token;
@property NSInteger parentID;
//@property (strong, nonatomic) NSString *forumName;
@property czzForum *forum;
@property (strong, nonatomic) NSString *forumID;

@property NSData *imgData;
-(BOOL)isReady;
-(NSMutableData*)makeRequestBody;
-(void)saveAccessToken;
@end
