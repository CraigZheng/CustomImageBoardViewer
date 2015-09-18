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
@property (strong, nonatomic) NSAttributedString *UID;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSAttributedString *content;
@property (strong, nonatomic) NSString *imgSrc;
@property (strong, nonatomic) NSString *thImgSrc;
@property (assign, nonatomic) BOOL lock;
@property (assign, nonatomic) BOOL sage;
@property (strong, nonatomic) NSDate *postDateTime;
@property (strong, nonatomic) NSDate *updateDateTime;
@property (assign, nonatomic) BOOL isParent;
@property (assign, nonatomic) NSInteger parentID;
#pragma mark - CONTENT CENSORING PROPERTIES
@property (assign, nonatomic) BOOL harmful;
@property (assign, nonatomic) BOOL blockContent;
@property (assign, nonatomic) BOOL blockImage;
@property (assign, nonatomic) BOOL blockAll;
#pragma mark - CLICKABLE CONTENT
@property (strong, nonatomic) NSMutableArray *replyToList;

@property (strong, nonatomic) czzForum *forum;

-(id)initWithJSONDictionary:(NSDictionary*)data;

-(NSAttributedString*)renderHTMLToAttributedString:(NSString*)htmlString;

-(BOOL)isEqual:(id)object;
-(NSUInteger)hash;
-(instancetype)initWithThreadID:(NSInteger)threadID;

-(czzWKThread *)watchKitThread;
@end
