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
@property UIView* parentView;
@end

@implementation czzOnScreenCommandViewController
@synthesize upperButton;
@synthesize bottomButton;
@synthesize backgroundView;
@synthesize parentViewController;
@synthesize timeoutInterval;
@synthesize timeoutTimer;
@synthesize parentView;
@synthesize size;
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    timeoutInterval = 2.0;
    size = CGSizeMake(60, 120);
//    [self giveViewRoundCornersAndShadow:backgroundView.layer];
    [self giveViewRoundCornersAndShadow:upperButton.layer];
    [self giveViewRoundCornersAndShadow:bottomButton.layer];
    upperButton.layer.backgroundColor = [UIColor clearColor].CGColor;
    bottomButton.layer.backgroundColor = [UIColor clearColor].CGColor;
    parentView = [[[czzAppDelegate sharedAppDelegate].window subviews] objectAtIndex:0];
//    parentView = [czzAppDelegate sharedAppDelegate].window;
//    [self updateFrame];

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
    if (parentViewController && [parentViewController respondsToSelector:scrollToTopSelector]) {
        [parentViewController performSelector:scrollToTopSelector];
    }
    [self updateTimer];

}

- (IBAction)bottomButtonAction:(id)sender {
    SEL scrollToBottomSelector = NSSelectorFromString(@"scrollTableViewToBottom");
    if (parentViewController && [parentViewController respondsToSelector:scrollToBottomSelector])
        [parentViewController performSelector:scrollToBottomSelector];
    [self updateTimer];
}

-(void)show
{
    self.view.hidden = NO;
    if (parentViewController) {
        if (parentView) {
            [self updateFrame];
            [parentViewController.view addSubview:self.view];
//            [parentView addSubview:self.view];
        }
    }
    [self updateTimer];
}

-(void)hide{
    self.view.hidden = YES;
    [self.view removeFromSuperview];
}

-(void)updateTimer {
    if (timeoutTimer.isValid) {
        [timeoutTimer invalidate];
    }
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeoutInterval target:self selector:@selector(hide) userInfo:nil repeats:NO];
}

-(void)updateFrame {
    if (UIInterfaceOrientationIsPortrait(parentViewController.interfaceOrientation)) {
        [self updateVerticalFrame];
    } else {
        [self updateHorizontalFrame];
    }
}

-(void)updateVerticalFrame {
    CGRect windowBounds = [czzAppDelegate sharedAppDelegate].window.bounds;
    CGRect myFrame = self.view.frame;
    CGFloat width = windowBounds.size.width;
    CGFloat height = windowBounds.size.height;
    CGFloat padding = size.width / 4;
    myFrame.origin.x = (width - size.width -  padding) / 2;
    myFrame.origin.y = height - size.height - padding * 3;
    myFrame.size.width = size.width;
    myFrame.size.height = size.height;
    self.view.frame = myFrame;
}

-(void)updateHorizontalFrame {
    CGRect windowBounds = [czzAppDelegate sharedAppDelegate].window.bounds;
    CGRect myFrame = self.view.frame;
    CGFloat width = windowBounds.size.height;
    CGFloat height = windowBounds.size.width;
    CGFloat padding = size.width / 4;
    myFrame.origin.x = width - size.width - padding * 2;
    myFrame.origin.y = height - size.height - padding * 3;
    myFrame.size.width = size.width;
    myFrame.size.height = size.height;
    self.view.frame = myFrame;

}

@end
