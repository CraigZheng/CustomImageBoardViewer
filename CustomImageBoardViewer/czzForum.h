//
//  czzForum.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzForum : NSObject <NSCoding>
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *header;
@property (assign, nonatomic) BOOL lock;
@property NSInteger cooldown;
@property NSInteger forumID;
@property NSDate *createdAt;
@property NSDate *updatedAt;

-(id)initWithJSONDictionary:(NSDictionary*)jsonDict;
+(id)initWithJSONDictionary:(NSDictionary*)jsonDict;
@end
