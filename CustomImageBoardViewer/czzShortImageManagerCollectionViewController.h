//
//  czzShortImageManagerCollectionViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 28/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define SHORT_IMAGE_MANAGER_VIEW_CONTROLLER @"short_image_manager_view_controller"

#import <UIKit/UIKit.h>

#import "czzModalViewController.h"
#import "czzImageCacheManager.h"
#import "czzAppDelegate.h"

@class czzShortImageManagerCollectionViewController;
@protocol czzShortImageManagerCollectionViewControllerProtocol <NSObject>
@optional
- (void)shortImageManager:(czzShortImageManagerCollectionViewController *)manager selectedImageWithIndex:(NSInteger)index inImages:(NSArray *)imageSource;
@end

@interface czzShortImageManagerCollectionViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) id<czzShortImageManagerCollectionViewControllerProtocol> delegate;
@property (weak, nonatomic) IBOutlet UICollectionView *managerCollectionView;
@property (weak, nonatomic) IBOutlet UIView *placeholderView;

@end
