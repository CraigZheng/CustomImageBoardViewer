//
//  czzOnScreenCommandViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 30/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzThreadViewController.h"


@interface czzOnScreenCommandViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIView *backgroundView;

@property (strong, nonatomic) IBOutlet UIButton *bottomButton;
@property (strong, nonatomic) IBOutlet UIButton *upperButton;
@property czzThreadViewController *threadViewController;
- (IBAction)upButtonAction:(id)sender;
- (IBAction)bottomButtonAction:(id)sender;
@end
