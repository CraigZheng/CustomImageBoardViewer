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
                self.name = [self readFromJsonDictionary:jsonDict withName:@"name"];
                self.header = [self readFromJsonDictionary:jsonDict withName:@"header"];
                self.lock = [[self readFromJsonDictionary:jsonDict withName:@"lock"] boolValue];
                self.cooldown = [[self readFromJsonDictionary:jsonDict withName:@"cooldown"] integerValue];
                self.forumID = [[self readFromJsonDictionary:jsonDict withName:@"id"] integerValue];
                self.createdAt = [NSDate dateWithTimeIntervalSince1970:[[self readFromJsonDictionary:jsonDict withName:@"createdAt"] doubleValue] / 1000];
                self.updatedAt = [NSDate dateWithTimeIntervalSince1970:[[self readFromJsonDictionary:jsonDict withName:@"updatedAt"] doubleValue] / 1000];
            }
            @catch (NSException *exception) {
            }
        }
    }
    return self;
}

/*
 at march 2015, the original A isle is dead, a new format is adapted by the new A isle
 */
-(id)initWithJSONDictionaryV2:(NSDictionary*)jsonDict {
    self = [super init];
    @try {
        {
            if (jsonDict) {
                self.forumID = [[self readFromJsonDictionary:jsonDict withName:@"id"] integerValue];
                self.name = [self readFromJsonDictionary:jsonDict withName:@"name"];
            }
            return self;
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    return nil;
}

-(id)readFromJsonDictionary:(NSDictionary*)dict withName:(NSString*)name {
    if ([[dict valueForKey:name] isEqual:[NSNull null]]) {
        return nil;
    }
    id value = [dict valueForKey:name];
    return value;
}

@end
