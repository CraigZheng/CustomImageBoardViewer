//
//  czzOnScreenCommandViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 30/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzOnScreenCommandViewController.h"

@interface czzOnScreenCommandViewController ()
@property NSTimer *timeoutTimer;
@end

@implementation czzOnScreenCommandViewController
@synthesize upperButton;
@synthesize bottomButton;
@synthesize backgroundView;
@synthesize threadViewController;
@synthesize timeoutInterval;
@synthesize timeoutTimer;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    timeoutInterval = 2.0;
//    [self giveViewRoundCornersAndShadow:backgroundView.layer];
    [self giveViewRoundCornersAndShadow:upperButton.layer];
    [self giveViewRoundCornersAndShadow:bottomButton.layer];
}

-(void)giveViewRoundCornersAndShadow:(CALayer*) layer{
    layer.masksToBounds = NO;
    layer.cornerRadius = 5;
    layer.shadowOffset = CGSizeMake(1, 1);
    layer.shadowRadius = 2;
    layer.shadowOpacity = 0.5;
    layer.shadowColor = [UIColor darkGrayColor].CGColor;

}

- (IBAction)upButtonAction:(id)sender {
    if (threadViewController)
        [threadViewController scrollTableViewToTop];
    [self updateTimer];

}

- (IBAction)bottomButtonAction:(id)sender {
    if (threadViewController)
        [threadViewController scrollTableViewToBottom];
    [self updateTimer];
}

-(void)show
{
    self.view.hidden = NO;
    [self updateTimer];
}

-(void)hide{
    self.view.hidden = YES;
}

-(void)updateTimer {
    if (timeoutTimer.isValid) {
        [timeoutTimer invalidate];
    }
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeoutInterval target:self selector:@selector(hide) userInfo:nil repeats:NO];
}
@end
