//
//  czzThread.h
//  CustomImageBoardViewer
//
//  Created by Craig on 27/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

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
#pragma mark - CONTENT CENSORING PROPERTIES
@property BOOL harmful;
@property BOOL blockContent;
@property BOOL blockImage;
@property BOOL blockAll;
#pragma mark - CLICKABLE CONTENT
@property NSMutableArray *replyToList;
-(id)initWithSMXMLElement:(SMXMLElement*)data;
-(id)initWithJSONDictionary:(NSDictionary*)data;
-(NSAttributedString*)renderHTMLToAttributedString:(NSString*)htmlString;

-(BOOL)isEqual:(id)object;
-(NSUInteger)hash;
@end
