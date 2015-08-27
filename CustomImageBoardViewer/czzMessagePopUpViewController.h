//
//  czzMessagePopUpViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/01/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#define MESSAGE_POPUP_VIEW_CONTROLLER_STORYBOARD_NAME @"MessagePopup"

#import <UIKit/UIKit.h>

@interface czzMessagePopUpViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *messageImageView;
@property (weak, nonatomic) IBOutlet UILabel *messageContentLabel;

@property UIImage *imageToShow;
@property (strong, nonatomic) NSString *messageToShow;

-(void)show;

@end
