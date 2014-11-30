//
//  czzShortImageManagerCollectionViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 28/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "czzImageCentre.h"
#import "czzAppDelegate.h"

@protocol czzShortImageManagerCollectionViewControllerProtocol <NSObject>
-(void)shouldOpenImagePath:(NSString*)imagePath;

@end

@interface czzShortImageManagerCollectionViewController : UICollectionViewController
@property id<czzShortImageManagerCollectionViewControllerProtocol> delegate;

@end
