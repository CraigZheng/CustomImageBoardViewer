//
//  czzFeedbackViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 29/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzFeedbackViewController.h"

@interface czzFeedbackViewController ()

@end

@implementation czzFeedbackViewController
@synthesize myFeedback;
@synthesize myNotification;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = myNotification.title;
}

@end
