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
                self.header = [self readFromJsonDictionary:jsonDict withName:@"msg"];
                self.lock = [[self readFromJsonDictionary:jsonDict withName:@"lock"] boolValue];
                self.cooldown = [[self readFromJsonDictionary:jsonDict withName:@"interval"] integerValue];
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

-(id)readFromJsonDictionary:(NSDictionary*)dict withName:(NSString*)name {
    if ([[dict valueForKey:name] isEqual:[NSNull null]]) {
        return nil;
    }
    id value = [dict valueForKey:name];
    return value;
}

#pragma mark - NSCoding protocol
-(id)initWithCoder:(NSCoder *)aDecoder {
    czzForum *forum = [czzForum new];
    forum.name = [aDecoder decodeObjectForKey:@"name"];
    forum.header = [aDecoder decodeObjectForKey:@"header"];
    forum.lock = [aDecoder decodeBoolForKey:@"lock"];
    forum.cooldown = [aDecoder decodeIntegerForKey:@"cooldown"];
    forum.forumID = [aDecoder decodeIntegerForKey:@"forumID"];
    forum.createdAt = [aDecoder decodeObjectForKey:@"createdAt"];
    forum.updatedAt = [aDecoder decodeObjectForKey:@"updatedAt"];
    return forum;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.header forKey:@"header"];
    [aCoder encodeBool:self.lock forKey:@"lock"];
    [aCoder encodeInteger:self.cooldown forKey:@"cooldown"];
    [aCoder encodeInteger:self.forumID forKey:@"forumID"];
    [aCoder encodeObject:self.createdAt forKey:@"createdAt"];
    [aCoder encodeObject:self.updatedAt forKey:@"updatedAt"];
    
}

+(id)initWithJSONDictionary:(NSDictionary *)jsonDict {
    return [[czzForum alloc] initWithJSONDictionary:jsonDict];
}


/**
 {
 "id": "18",
 "fgroup": "6",
 "sort": "1",
 "name": "值班室",
 "showName": "",
 "msg": "<p>&bull;本版发文间隔为15秒。<br />\r\n&bull;请在此举报不良内容，并附上串地址以及发言者ID。如果是回复串，请附上&ldquo;回应&rdquo;链接的地址，格式为&gt;&gt;No.串ID或&gt;&gt;No.回复ID<br />\r\n&bull;主站相关问题反馈、建议请在这里留言<br />\r\n&bull;已处理的举报将锁定。</p>\r\n",
 "interval": "15",
 "createdAt": "2011-09-30 23:55:20",
 "updateAt": "2015-07-26 15:39:24",
 "status": "n"
 }
 */
@end
