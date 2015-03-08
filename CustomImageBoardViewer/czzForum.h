//
//  czzForum.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzForum : NSObject
@property NSString *name;
@property NSString *header;
@property BOOL lock;
@property NSInteger cooldown;
@property NSInteger forumID;
@property NSDate *createdAt;
@property NSDate *updatedAt;

-(id)initWithJSONDictionary:(NSDictionary*)jsonDict;
-(id)initWithJSONDictionaryV2:(NSDictionary*)jsonDict;
@end
