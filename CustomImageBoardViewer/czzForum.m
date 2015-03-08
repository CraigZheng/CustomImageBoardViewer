//
//  czzForum.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzForum.h"

@implementation czzForum
@synthesize name, header, lock, cooldown, forumID, createdAt, updatedAt;

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

-(id)readFromJsonDictionary:(NSDictionary*)dict withName:(NSString*)dictName {
    if ([[dict valueForKey:dictName] isEqual:[NSNull null]]) {
        return nil;
    }
    id value = [dict valueForKey:dictName];
    return value;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:name forKey:@"name"];
    [aCoder encodeObject:header forKey:@"header"];
    [aCoder encodeBool:lock forKey:@"lock"];
    [aCoder encodeInteger:cooldown forKey:@"cooldown"];
    [aCoder encodeInteger:forumID forKey:@"forumID"];
    [aCoder encodeObject:createdAt forKey:@"createdAt"];
    [aCoder encodeObject:updatedAt forKey:@"updatedAt"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.header = [aDecoder decodeObjectForKey:@"header"];
        self.lock = [aDecoder decodeBoolForKey:@"lock"];
        self.cooldown = [aDecoder decodeIntegerForKey:@"cooldown"];
        self.forumID = [aDecoder decodeIntegerForKey:@"forumID"];
        self.createdAt = [aDecoder decodeObjectForKey:@"createdAt"];
        self.updatedAt = [aDecoder decodeObjectForKey:@"updatedAt"];
    }
    return self;
}

@end
