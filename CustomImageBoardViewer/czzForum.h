//
//  czzForum.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzSettingsCentre.h"

typedef enum {
    FORUM_PARSER_AISLE = 1,
    FORUM_PARSER_A_DAO = 2
} FORUM_PARSER_TYPE;

@interface czzForum : NSObject <NSCoding>
@property NSString *name;
@property NSString *header;
@property BOOL lock;
@property NSInteger cooldown;
@property NSInteger forumID;
@property NSDate *createdAt;
@property NSDate *updatedAt;
@property NSString *forumURL;
@property NSString *imageHost;
@property FORUM_PARSER_TYPE parserType;

-(id)initWithJSONDictionary:(NSDictionary*)jsonDict;
-(NSDictionary*)toDictionary;

@end
