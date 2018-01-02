//
//  czzForumsViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kForumPickedNotification;
extern NSString * const kPickedForum;
extern NSString * const kPickedTimeline;

@interface czzForumsViewController : UITableViewController
@property (strong, nonatomic) NSArray *forums;
@end
