//
//  czzMessagePopUpViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/01/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzModalViewController.h"

@interface czzMessagePopUpViewController : czzModalViewController
@property (strong, nonatomic) UIImageView *messageImageView;
@property (strong, nonatomic) UILabel *messageContentLabel;

@property (strong, nonatomic) UIImage *imageToShow;
@property (strong, nonatomic) NSString *messageToShow;

@end
