//
//  czzForumsViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@import GoogleMobileAds;

extern NSString * const kForumPickedNotification;
extern NSString * const kPickedForum;


@interface czzForumsViewController : UITableViewController
@property (strong, nonatomic) GADBannerView *bannerView_;
@property (strong, nonatomic) NSArray *forums;
@end
