//
//  czzThread.h
//  CustomImageBoardViewer
//
//  Created by Craig on 27/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "czzForum.h"

@class SMXMLElement;

@interface czzThread : NSObject
@property NSInteger responseCount;
@property NSInteger ID;
@property NSAttributedString *UID;
@property NSString *name;
@property NSString *email;
@property NSString *title;
@property NSAttributedString *content;
@property NSString *imgSrc;
@property NSString *thImgSrc;
@property BOOL lock;
@property BOOL sage;
@property NSDate *postDateTime;
@property NSDate *updateDateTime;
@property BOOL isParent;
@property NSInteger parentID;
#pragma mark - CONTENT CENSORING PROPERTIES
@property BOOL harmful;
@property BOOL blockContent;
@property BOOL blockImage;
@property BOOL blockAll;
#pragma mark - CLICKABLE CONTENT
@property NSMutableArray *replyToList;

@property czzForum *forum;

-(id)initWithJSONDictionary:(NSDictionary*)data;
-(instancetype)initWithJSONDictionaryV2:(NSDictionary *)data;

-(NSAttributedString*)renderHTMLToAttributedString:(NSString*)htmlString;

-(BOOL)isEqual:(id)object;
-(NSUInteger)hash;
-(instancetype)initWithThreadID:(NSInteger)threadID;
@end
