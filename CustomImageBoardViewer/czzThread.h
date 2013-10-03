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
@property NSString *UID;
@property NSString *name;
@property NSString *email;
@property NSString *title;
@property NSAttributedString *content;
@property NSString *imgScr;
@property NSString *thImgSrc;
@property BOOL lock;
@property BOOL sage;
@property NSDate *postDateTime;
@property NSDate *updateDateTime;
@property NSMutableArray *replyToList;

-(id)initWithSMXMLElement:(SMXMLElement*)data;

-(BOOL)isEqual:(id)object;
-(NSUInteger)hash;
@end
