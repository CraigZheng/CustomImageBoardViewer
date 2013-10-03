//
//  czzForumGroup.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzForumGroup.h"

@implementation czzForumGroup
-(id)init{
    self = [super init];
    if (self){
        self.forumNames = [NSMutableArray new];
    }
    return self;
}
@end
