//
//  czzForum.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "czzWKForum.h"

@interface czzForum : NSObject <NSCoding>
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *screenName;
@property (strong, nonatomic) NSString *header;
@property (assign, nonatomic) BOOL lock;
@property (assign, nonatomic) NSInteger cooldown;
@property (assign, nonatomic) NSInteger forumID;
@property (strong, nonatomic) NSDate *createdAt;
@property (strong, nonatomic) NSDate *updatedAt;

-(id)initWithJSONDictionary:(NSDictionary*)jsonDict;
+(id)initWithJSONDictionary:(NSDictionary*)jsonDict;

-(czzWKForum*)watchKitForum;
@end
