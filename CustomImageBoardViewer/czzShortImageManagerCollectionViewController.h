//
//  czzShortImageManagerCollectionViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 28/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define SHORT_IMAGE_MANAGER_VIEW_CONTROLLER @"short_image_manager_view_controller"

#import <UIKit/UIKit.h>

#import "czzImageCentre.h"
#import "czzAppDelegate.h"

@protocol czzShortImageManagerCollectionViewControllerProtocol <NSObject>
@optional
-(void)userTappedOnImageWithPath:(NSString*)imagePath;

@end

@interface czzShortImageManagerCollectionViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) id<czzShortImageManagerCollectionViewControllerProtocol> delegate;
@property (weak, nonatomic) IBOutlet UICollectionView *managerCollectionView;
@property (strong, nonatomic) NSMutableArray *downloadedImages;
@property (weak, nonatomic) IBOutlet UIView *placeholderView;
@property (strong, nonatomic) UIViewController *hostViewController;

@property (assign, nonatomic) BOOL isShowing;

-(void)updateProgressForDownloader:(czzImageDownloader*)downloader;
-(void)imageDownloaded:(NSString*)imgPath;

- (IBAction)tapOnViewAction:(id)sender;

-(void)show;
@end
