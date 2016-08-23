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

@class czzForumManager;
@protocol czzForumManagerDelegate <NSObject>
-(void)forumManagerBeginDownloading:(czzForumManager*)manager;
-(void)forumManager:(czzForumManager*)manager downloadCompleted:(BOOL)successful;
@end

@interface czzForumManager : NSObject
@property (nonatomic, weak) id<czzForumManagerDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *forumGroups;
@property (nonatomic) NSArray *forums;
@property (strong, nonatomic) NSMutableArray * customForums;

- (void)addCustomForumWithName:(NSString *)forumName id:(NSInteger)forumID;
- (void)updateForums:(void(^)(BOOL success, NSError *error))completionHandler;

+ (instancetype)sharedManager;

@end
