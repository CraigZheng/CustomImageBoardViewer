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
@property NSTimer *updateTextTimer;
@property NSTimeInterval updateInterval;
@end

@implementation czzNotificationBannerViewController
@synthesize statusIcon;
@synthesize dismissButton;
@synthesize headerLabel;
@synthesize parentView;
@synthesize constantHeight;
@synthesize needsToBePresented;
@synthesize currentNotification;
@synthesize notifications;
@synthesize updateInterval;
@synthesize updateTextTimer;

int counter = 0;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    notifications = [NSMutableArray new];
    self.view.layer.shadowOffset = CGSizeMake(4, 4);
    self.view.layer.shadowRadius = 2;
    constantHeight = 44; //the height for this view, should not be changed at all time
    [self updateFrameForVertical];
    updateInterval = 5;
    updateTextTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval target:self selector:@selector(updateTextTesting) userInfo:nil repeats:YES];
}

-(void)updateTextTesting {
    [[czzAppDelegate sharedAppDelegate] doSingleViewHideAnimation:headerLabel :kCATransitionFade :0.4];
    headerLabel.text = [NSString stringWithFormat:@"update text counter %d", counter];
    counter ++;
    [[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:headerLabel :kCATransitionFade :0.4];
}

-(void)setNeedsToBePresented:(BOOL)need {
    needsToBePresented = need;
    if (needsToBePresented) {
        [self show];
    } else {
        [self hide];
    }
}

-(void)show {
    if (parentView && !self.view.superview)
        [parentView addSubview:self.view];
    [[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:self.view :kCATransitionFromTop :0.2];
}

-(void)hide {
    [[czzAppDelegate sharedAppDelegate] doSingleViewHideAnimation:self.view :kCATransitionFromBottom :0.2];
}

- (IBAction)dismissAction:(id)sender {
    [self hide];
}

- (IBAction)tapOnViewAction:(id)sender {
    NSLog(@"tap on view");
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    //theres an ugly transtition, therefore need to hide it before showing it again
    self.view.hidden = YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [self updateFrameForHorizontal];
    } else {
        [self updateFrameForVertical];
    }
}

-(void)updateFrameForVertical {
    if (parentView) {
        CGRect parentFrame = parentView.bounds;
        CGRect myFrame = self.view.frame;
        myFrame.size.width = parentFrame.size.width;
        myFrame.size.height = constantHeight;
        myFrame.origin.y = parentFrame.size.height - myFrame.size.height;
        self.view.frame = myFrame;
    }
    if (needsToBePresented) {
        [[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:self.view :kCATransitionFromTop :0.2];
    }
}

-(void)updateFrameForHorizontal {
    self.view.hidden = YES;
    if (parentView) {
        CGRect parentFrame = parentView.bounds;
        CGRect myFrame = self.view.frame;
        myFrame.size.width = parentFrame.size.width;
        myFrame.size.height = constantHeight;
        myFrame.origin.y = parentFrame.size.height - myFrame.size.height;
        self.view.frame = myFrame;
    }
    if (needsToBePresented) {
        [[czzAppDelegate sharedAppDelegate] doSingleViewShowAnimation:self.view :kCATransitionFromTop :0.2];
    }
}
@end
