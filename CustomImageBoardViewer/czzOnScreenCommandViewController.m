//
//  czzOnScreenCommandViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 30/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzOnScreenCommandViewController.h"
#import "czzAppDelegate.h"
#import "czzThreadTableView.h"


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
    // Initially should be hidden
    [self hide];
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
    [self.delegate onScreenCommandTapOnUp:self];
    [self updateTimer];

}

- (IBAction)bottomButtonAction:(id)sender {
    [self.delegate onScreenCommandTapOnDown:self];
    [self updateTimer];
}

-(void)show
{
    if (self.view.hidden) {
        size = CGSizeMake(60, 120);
        if (!self.view.superview) {
            [AppDelegate.window addSubview:self.view];
        }
        
        [self updateFrame];

        self.view.hidden = NO;
    }
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

-(void)updateFrame {
    if (UIInterfaceOrientationIsPortrait(NavigationManager.delegate.interfaceOrientation)) {
        [self updateVerticalFrame];
    } else {
        [self updateHorizontalFrame];
    }
}

-(void)updateVerticalFrame {
    CGRect windowBounds = AppDelegate.window.bounds;
    if (self.view.superview) {
        windowBounds = self.view.superview.frame;
    }
    CGRect myFrame = self.view.frame;
    CGFloat width = windowBounds.size.width;
    CGFloat height = windowBounds.size.height;
    CGFloat padding = size.width / 2;
    myFrame.origin.x = (width - size.width) / 2;
    myFrame.origin.y = height - size.height - padding * 3;
    myFrame.size.width = size.width;
    myFrame.size.height = size.height;
    self.view.frame = myFrame;
}

-(void)updateHorizontalFrame {
    CGRect windowBounds = AppDelegate.window.bounds;
    if (self.view.superview) {
        windowBounds = self.view.superview.frame;
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

#pragma mark - setter
-(void)setDelegate:(czzThreadTableView<czzOnScreenCommandViewControllerDelegate>*)delegate {
    _delegate = delegate;
    // Add this view to delegate's superview, so it won't scroll with the delegate
    if (delegate.superview) {
        [delegate.superview addSubview:self.view];
    }
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:@"OnScreenCommand" bundle:nil] instantiateInitialViewController];
}

@end
