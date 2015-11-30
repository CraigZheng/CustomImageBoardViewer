//
//  czzWKForum.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 20/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWKForum.h"

@implementation czzWKForum

-(instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    self.name = [dict objectForKey:@"name"];
    self.forumID = [[dict objectForKey:@"forumID"] integerValue];
    return self;
}

-(NSDictionary *)encodeToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:@(self.forumID) forKey:@"forumID"];
    [dict setObject:self.name forKey:@"name"];
    return dict;
}

@end
