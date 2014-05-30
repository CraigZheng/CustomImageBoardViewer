//
//  czzOnScreenCommandViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 30/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzOnScreenCommandViewController.h"

@interface czzOnScreenCommandViewController ()

@end

@implementation czzOnScreenCommandViewController
@synthesize upperButton;
@synthesize bottomButton;
@synthesize backgroundView;
@synthesize threadViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    backgroundView.layer.masksToBounds = NO;
    backgroundView.layer.cornerRadius = 5;
    backgroundView.layer.shadowOffset = CGSizeMake(1, 1);
    backgroundView.layer.shadowRadius = 5;
    backgroundView.layer.shadowOpacity = 0.5;
    backgroundView.layer.shadowColor = [UIColor darkGrayColor].CGColor;

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)upButtonAction:(id)sender {
    if (threadViewController)
        [threadViewController scrollTableViewToTop];
}

- (IBAction)bottomButtonAction:(id)sender {
    if (threadViewController)
        [threadViewController scrollTableViewToBottom];
}
@end
