//
//  czzForum.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzForum.h"

@implementation czzForum

-(id)initWithJSONDictionary:(NSDictionary *)jsonDict {
    self = [super init];
    if (self) {
        if (jsonDict) {
            @try {
                self.name = [jsonDict objectForKey:@"name"];
                self.header = [jsonDict objectForKey:@"header"];
                self.lock = [[jsonDict objectForKey:@"lock"] boolValue];
                self.cooldown = [[jsonDict objectForKey:@"cooldown"] integerValue];
                self.forumID = [[jsonDict objectForKey:@"id"] integerValue];
                self.createdAt = [NSDate dateWithTimeIntervalSince1970:[[jsonDict objectForKey:@"createdAt"] doubleValue]];
                self.updatedAt = [NSDate dateWithTimeIntervalSince1970:[[jsonDict objectForKey:@"updatedAt"] doubleValue]];
            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception);
            }
        }
    }
    return self;
}

@end
