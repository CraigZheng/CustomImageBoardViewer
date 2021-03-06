//
//  czzForumManager.h
//  CustomImageBoardViewer
//
//  Created by Craig on 19/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *kCustomForumDidChangeNotification = @"kCustomForumDidChangeNotification";

@class czzForum, czzForumManager, czzForumGroup;
@protocol czzForumManagerDelegate <NSObject>
-(void)forumManagerBeginDownloading:(czzForumManager*)manager;
-(void)forumManager:(czzForumManager*)manager downloadCompleted:(BOOL)successful;
@end

@interface czzForumManager : NSObject
@property (nonatomic, weak) id<czzForumManagerDelegate> delegate;
@property (nonatomic, readonly) NSMutableArray<czzForumGroup*> *forumGroups;
@property (nonatomic) NSArray<czzForum *> *forums;
@property (strong, nonatomic) NSMutableArray * customForums;

- (void)addCustomForumWithName:(NSString *)forumName forumID:(NSInteger)forumID;
- (void)removeCustomForum:(czzForum*)forum;
- (void)updateForums:(void(^)(BOOL success, NSError *error))completionHandler;
- (void)resetForums;

+ (instancetype)sharedManager;

@end
