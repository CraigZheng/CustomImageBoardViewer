//
//  czzForumGroup.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzForumGroup.h"
#import "czzForum.h"

@implementation czzForumGroup
-(id)init{
    self = [super init];
    if (self){
        self.forums = [NSMutableArray new];
    }
    return self;
}

+ (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    czzForumGroup *forumGroup = [czzForumGroup new];
    
    NSString *name = [dictionary objectForKey:@"name"];
    NSArray *forums = [dictionary objectForKey:@"forums"];
    
    forumGroup.area = name;
    for (NSDictionary *dictionary in forums) {
        [forumGroup.forums addObject:[czzForum initWithJSONDictionary:dictionary]];
    }
    
    return forumGroup;
}

@end
