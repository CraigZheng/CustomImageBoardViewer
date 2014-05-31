//
//  czzNotificationBannerViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 31/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzNotificationBannerViewController.h"
#import "czzAppDelegate.h"

@interface czzNotificationBannerViewController ()

@end

@implementation czzNotificationBannerViewController
@synthesize statusIcon;
@synthesize dismissButton;
@synthesize headerLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

-(void)show {

}

-(void)hide {
    
}

- (IBAction)dismissAction:(id)sender {
    
}

- (IBAction)tapOnViewAction:(id)sender {
    NSLog(@"tap on view");
}
@end
