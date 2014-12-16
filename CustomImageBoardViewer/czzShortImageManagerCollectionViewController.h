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
@property id<czzShortImageManagerCollectionViewControllerProtocol> delegate;
@property (weak, nonatomic) IBOutlet UICollectionView *managerCollectionView;
@property BOOL isShowing;

-(void)updateProgressForDownloader:(czzImageDownloader*)downloader;

- (IBAction)tapOnViewAction:(id)sender;

-(void)show;
@end
