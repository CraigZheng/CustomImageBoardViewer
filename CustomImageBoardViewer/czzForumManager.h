//
//  czzForumManager.h
//  CustomImageBoardViewer
//
//  Created by Craig on 19/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzForum.h"
#import "czzForumGroup.h"

@interface czzForumManager : NSObject
@property (nonatomic, strong) NSMutableArray *forumGroups;
@property (nonatomic) NSArray *forums;
- (void)updateForums:(void(^)(BOOL success, NSError *error))completionHandler;

+ (instancetype)sharedManager;

@end
