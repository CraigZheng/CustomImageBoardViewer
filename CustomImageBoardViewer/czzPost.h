//
//  czzReply.h
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzPost : NSObject
@property NSString *name;
@property NSString *email;
@property NSString *title;
@property NSString *content;
@property NSString *access_token;
@property NSInteger parentID;
@property NSString *forumName;

@property NSData *imgData;
-(BOOL)isReady;
-(NSMutableData*)makeRequestBody;
-(void)saveAccessToken;
@end
