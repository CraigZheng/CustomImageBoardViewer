//
//  czzCustomSlideAnimationViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 5/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzCustomSlideAnimationViewController.h"
#import "CPWearableViewCustomTransitioningAnimator.h"

@interface czzCustomSlideAnimationViewController () <UIViewControllerTransitioningDelegate>

@end

@implementation czzCustomSlideAnimationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.modalTransitionStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self;
    
}

#pragma mark - UIViewControllerTransitioningDelegate
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [CPWearableViewCustomTransitioningAnimator new];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    CPWearableViewCustomTransitioningAnimator *animator = [CPWearableViewCustomTransitioningAnimator new];
    animator.isDismissing = self.isDismissing;
    return animator;
}


@end
