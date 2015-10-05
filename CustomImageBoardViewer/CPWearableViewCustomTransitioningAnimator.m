//
//  CPWearableViewCustomTransition.m
//  CashByOptusPhone
//
//  Created by Craig on 18/05/2015.
//  Copyright (c) 2015 Singtel Optus Pty Ltd. All rights reserved.
//

#import "CPWearableViewCustomTransitioningAnimator.h"

@implementation CPWearableViewCustomTransitioningAnimator

#pragma mark - UIViewControllerAnimatedTransitioning
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;
    UIView *containerView = [transitionContext containerView];
    NSTimeInterval duration = [self transitionDuration:transitionContext];

    //perform the animation
    //make the container view twice the size of the current screen size
    CGRect twiceScreenSize = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width * 2, [UIScreen mainScreen].bounds.size.height);
    containerView.frame = twiceScreenSize;
    //adjust the sizes for fromView and toView
    fromView.frame = toView.frame = [UIScreen mainScreen].bounds;
    if (self.isDismissing) {
        //is dismissing, position from right on the right and toView on the left, animate container view from right to left
        fromView.frame = CGRectMake(fromView.frame.size.width, 0, fromView.frame.size.width, fromView.frame.size.height);
        //at the begining, container view should be half way at the centre(x = negative number), then move to left(x = 0);
        containerView.frame = CGRectMake(-fromView.frame.origin.x, 0, containerView.frame.size.width, containerView.frame.size.height);
//        [containerView addSubview:fromView];
        [containerView addSubview:toView];
        [UIView animateWithDuration:duration animations:^{
            containerView.frame = CGRectMake(0, 0, containerView.frame.size.width, containerView.frame.size.height);
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    } else {
        //is presenting, position the from view on the left and toView on the right, animate x from 0 to the beginning of to view
        toView.frame = CGRectMake(fromView.frame.size.width, 0, toView.frame.size.width, toView.frame.size.height);
//        [containerView addSubview:fromView];
        [containerView addSubview:toView];
        [UIView animateWithDuration:duration animations:^{
            CGRect frame = CGRectMake(0, 0, toView.frame.size.width, toView.frame.size.height);
            toView.frame = frame;
            fromView.frame = CGRectMake(-fromView.frame.size.width, 0, fromView.frame.size.width, fromView.frame.size.height);
        } completion:^(BOOL finished) {
            // Add the following line before completing the transition
            [[[UIApplication sharedApplication] keyWindow] sendSubviewToBack:toVC.view];
            
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            DLog(@"%s animation transition completed", __func__);
        }];
    }
}



@end
