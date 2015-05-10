//
//  czzForumsViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IIViewDeckController.h"
#import "GADBannerView.h"

#define kForumPickedNotification @"ForumNamePicked"
#define kPickedForum @"ForumName"

@interface czzForumsViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITableView *forumsTableView;
@property GADBannerView *bannerView_;
@end
