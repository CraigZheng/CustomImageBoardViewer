//
//  czzOnScreenCommandViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 30/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzOnScreenCommandViewController.h"
#import "czzAppDelegate.h"

@interface czzOnScreenCommandViewController ()
@property NSTimer *timeoutTimer;
@end

@implementation czzOnScreenCommandViewController
@synthesize upperButton;
@synthesize bottomButton;
@synthesize timeoutInterval;
@synthesize timeoutTimer;
@synthesize size;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    timeoutInterval = 2.0;
    [self giveViewRoundCornersAndShadow:self.view.layer];
    [self giveViewRoundCornersAndShadow:upperButton.layer];
    [self giveViewRoundCornersAndShadow:bottomButton.layer];
    upperButton.layer.backgroundColor = [UIColor clearColor].CGColor;
    bottomButton.layer.backgroundColor = [UIColor clearColor].CGColor;
    self.view.frame = CGRectMake(0, 0, 60, 120);
    self.view.backgroundColor = [UIColor clearColor];
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
    SEL scrollToTopSelector = NSSelectorFromString(@"scrollTableViewToTop");
    if (self.parentViewController && [self.parentViewController respondsToSelector:scrollToTopSelector]) {
        SuppressPerformSelectorLeakWarning(
                                           [self.parentViewController performSelector:scrollToTopSelector];
                                           );
    }
    [self updateTimer];

}

- (IBAction)bottomButtonAction:(id)sender {
    SEL scrollToBottomSelector = NSSelectorFromString(@"scrollTableViewToBottom");
    if (self.parentViewController && [self.parentViewController respondsToSelector:scrollToBottomSelector])
    {
        SuppressPerformSelectorLeakWarning(
                                           [self.parentViewController performSelector:scrollToBottomSelector];

        );
    }
    [self updateTimer];
}

-(void)show
{
    if (self.view.hidden) {
        size = CGSizeMake(60, 120);
        if (self.parentViewController) {
            if (!self.view.superview)
                [self.parentViewController.view addSubview:self.view];
            
            [self updateFrame];
            //            [parentView addSubview:self.view];
        }
        self.view.hidden = NO;
    }
    [self updateTimer];
}

-(void)hide{
    self.view.hidden = YES;
//    [self.view removeFromSuperview];
}

-(void)updateTimer {
    if (timeoutTimer.isValid) {
        [timeoutTimer invalidate];
    }
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeoutInterval target:self selector:@selector(hide) userInfo:nil repeats:NO];
}

-(void)updateFrame {
    if (UIInterfaceOrientationIsPortrait(self.parentViewController.interfaceOrientation)) {
        [self updateVerticalFrame];
    } else {
        [self updateHorizontalFrame];
    }
}

-(void)updateVerticalFrame {
    CGRect windowBounds = AppDelegate.window.bounds;
    if (self.parentViewController) {
        windowBounds = self.parentViewController.view.frame;
    }
    CGRect myFrame = self.view.frame;
    CGFloat width = windowBounds.size.width;
    CGFloat height = windowBounds.size.height;
    CGFloat padding = size.width / 2;
    myFrame.origin.x = (width - size.width) / 2;
    myFrame.origin.y = height - size.height - padding * 2;
    myFrame.size.width = size.width;
    myFrame.size.height = size.height;
    self.view.frame = myFrame;
}

-(void)updateHorizontalFrame {
    CGRect windowBounds = AppDelegate.window.bounds;
    if (self.parentViewController) {
        windowBounds = self.parentViewController.view.frame;
    }
    CGRect myFrame = self.view.frame;
    CGFloat width = windowBounds.size.width;
    CGFloat height = windowBounds.size.height;
    CGFloat padding = size.width / 2;
    myFrame.origin.x = width - size.width - padding * 3;
    myFrame.origin.y = height - size.height - padding * 3;
    myFrame.size.width = size.width;
    myFrame.size.height = size.height;
    self.view.frame = myFrame;

}

@end
