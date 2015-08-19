//
//  czzForumManager.h
//  CustomImageBoardViewer
//
//  Created by Craig on 19/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface czzForumManager : NSObject
@property (nonatomic, strong) NSMutableArray *forumGroups;

- (void)updateForums:(void(^)(BOOL success, NSError *error))completionHandler;

+ (instancetype)sharedManager;

@end
