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
#import "czzSettingsCentre.h"

@interface czzForumManager : NSObject <czzURLDownloaderProtocol>
@property (nonatomic) NSMutableArray *availableForums;
@property NSMutableArray *allForums; //including those that are locked
@property czzURLDownloader *forumDownloader;

-(NSArray*)parseJsonForForum:(NSData*)jsonData;

+(id)sharedInstance;
@end
