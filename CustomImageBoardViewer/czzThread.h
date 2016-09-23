//
//  czzThread.h
//  CustomImageBoardViewer
//
//  Created by Craig on 27/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "czzForum.h"
#import "czzWKThread.h"

@class SMXMLElement;

@interface czzThread : NSObject
@property (assign, nonatomic) NSInteger responseCount;
@property (assign, nonatomic) NSInteger ID;
@property (strong, nonatomic) NSString *UID;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSAttributedString *content;
@property (readonly, nonatomic) NSString *contentSummary;
@property (strong, nonatomic) NSString *imgSrc;
@property (strong, nonatomic) NSString *thImgSrc;
@property (assign, nonatomic) BOOL lock;
@property (assign, nonatomic) BOOL sage;
@property (assign, nonatomic) BOOL admin;
@property (strong, nonatomic) NSDate *postDateTime;
@property (strong, nonatomic) NSDate *updateDateTime;
@property (assign, nonatomic) NSInteger parentID;
#pragma mark - CLICKABLE CONTENT
@property (strong, nonatomic) NSMutableArray *replyToList;

-(NSAttributedString*)renderHTMLToAttributedString:(NSString*)htmlString;

-(BOOL)isEqual:(id)object;
-(NSUInteger)hash;
-(id)initWithJSONDictionary:(NSDictionary*)data;
-(instancetype)initWithThreadID:(NSInteger)threadID;
-(instancetype)initWithParentID:(NSInteger)parentID;

-(czzWKThread *)watchKitThread;

/*
 {
 "id": "7300953",
 "img": "2015-12-12/566b717ee1bec",
 "ext": ".png",
 "now": "2015-12-12(六)08:59:42",
 "userid": "GFlBXe8",
 "name": "无名氏",
 "email": "",
 "title": "无标题",
 "content": "&gt;&gt;No.7299829",
 "sage": "0",
 "admin": "0"
 }
 */
@end
