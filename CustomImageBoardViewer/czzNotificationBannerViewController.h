//
//  czzNotificationBannerViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 31/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface czzNotificationBannerViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIImageView *statusIcon;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;


- (IBAction)dismissAction:(id)sender;
- (IBAction)tapOnViewAction:(id)sender;

-(void)show;
-(void)hide;
@end
