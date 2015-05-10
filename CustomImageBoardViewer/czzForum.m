//
//  czzForum.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/08/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzForum.h"

@implementation czzForum
@synthesize name, header, lock, cooldown, forumID, createdAt, updatedAt, forumURL, threadContentURL;

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
                
                self.forumURL = [self readFromJsonDictionary:jsonDict withName:@"targetURL"];
                if (!self.forumURL.length) {
                    if (self.name)
                        self.forumURL = @"http://h.nimingban.com/api/<kForum>?page=<kPageNumber>";
                }
                self.threadContentURL = [self readFromJsonDictionary:jsonDict withName:@"threadContentURL"];
                if (!self.threadContentURL.length) {
                    self.threadContentURL = @"http://h.nimingban.com/api/t/<THREAD_ID>?page=<kPageNumber>";
                }
                
                self.imageHost = [self readFromJsonDictionary:jsonDict withName:@"imageHost"];
                if (!self.imageHost.length) {
                    //give it a default image host
                    self.imageHost = [settingCentre image_host];
                }
                self.parserType = [[self readFromJsonDictionary:jsonDict withName:@"forumParser"] integerValue];
                if (self.parserType == 0) {
                    //default to Aisle format
                    self.parserType = 1;
                }
            }
            @catch (NSException *exception) {
            }
        }
    }
    return self;
}

-(NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSDictionary *allProperties = [NSObject classPropsFor:self.class];
    for (NSString *propertyKey in allProperties.allKeys) {
        @try {
            id value = [self valueForKey:propertyKey];
            if (value) {
                //json format doesnt support NSDate
                if ([value isKindOfClass:[NSDate class]]) {
                    [dict setObject:@([value timeIntervalSince1970] * 1000) forKey:propertyKey];
                }
                else
                    [dict setObject:value forKey:propertyKey];
            }
        }
        @catch (NSException *exception) {
            DLog(@"%@", exception);
        }
    }
    return dict;
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
