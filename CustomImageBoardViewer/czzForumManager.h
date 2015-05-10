//
//  czzForumManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "czzURLDownloader.h"
#import "czzForum.h"
#import "czzForumGroup.h"
#import "czzSettingsCentre.h"

@class czzForumManager;
@protocol czzForumManagerDelegate <NSObject>
-(void)forumManager:(czzForumManager*)manager updated:(BOOL)wasSuccessful;
@optional
-(void)forumManagerDidStartUpdate:(czzForumManager*)manager;
@end

@interface czzForumManager : NSObject <czzURLDownloaderProtocol>

@property NSMutableArray *allForumGroups; //including those that are locked

@property id<czzForumManagerDelegate> delegate;

-(void)updateForum;
-(NSArray*)parseJsonForForum:(NSData*)jsonData;

+(id)sharedInstance;
@end
