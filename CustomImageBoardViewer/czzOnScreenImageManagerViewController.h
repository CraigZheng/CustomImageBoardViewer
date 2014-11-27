//
//  czzOnScreenImageManagerViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 18/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface czzOnScreenImageManagerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *mainIcon;
- (IBAction)tapOnImageManagerIconAction:(id)sender;
@end