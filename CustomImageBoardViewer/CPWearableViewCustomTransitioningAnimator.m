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

    // Adjust the size, just in case.
    fromView.frame = toView.frame = [UIScreen mainScreen].bounds;
    if (self.isDismissing) {
        // Is dismissing
        
        // Add shadow to the fromView
        fromView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
        fromView.layer.shadowOpacity = 0.8;
        fromView.layer.shadowPath = [UIBezierPath bezierPathWithRect:toView.frame].CGPath;
        fromView.layer.shadowRadius = 5;

        // fromView positions to full screen.
        fromView.frame = CGRectMake(0, 0, fromView.frame.size.width, fromView.frame.size.height);

        // toView positions to half way to the left.
        CGRect toViewRect = toView.frame;
        toViewRect.origin.x = -(toViewRect.size.width / 2);
        toView.frame = toViewRect;
        [containerView addSubview:toView];
        // fromView should be on top of toView.
        [containerView bringSubviewToFront:fromView];
        [UIView animateWithDuration:duration animations:^{
            // fromView move out of the screen.
            CGRect fromViewRect = fromView.frame;
            fromViewRect.origin.x = fromViewRect.size.width;
            fromView.frame = fromViewRect;
            
            // toView move to full screen.
            CGRect toViewRect = toView.frame;
            toViewRect.origin.x = 0;
            toView.frame = toViewRect;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    } else {
        // Is presenting
        
        // Add shadow, which represents a layer of depth.
        toView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
        toView.layer.shadowOpacity = 0.8;
        toView.layer.shadowPath = [UIBezierPath bezierPathWithRect:toView.frame].CGPath;
        toView.layer.shadowRadius = 5;
        
        // Position the toView on the right side of the screen.
        toView.frame = CGRectMake(fromView.frame.size.width, 0, toView.frame.size.width, toView.frame.size.height);
        
        [containerView addSubview:toView];
        [UIView animateWithDuration:duration animations:^{
            // toView move to full screen.
            CGRect toViewRect = toView.frame;
            toViewRect.origin.x = 0;
            toView.frame = toViewRect;
            // fromView move half out of the screen
            CGRect fromViewRect = fromView.frame;
            fromViewRect.origin.x = -(fromViewRect.size.width / 2);
            fromView.frame = fromViewRect;
        } completion:^(BOOL finished) {
            // Add the following line before completing the transition
            [[[UIApplication sharedApplication] keyWindow] sendSubviewToBack:toVC.view];
            
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            DLog(@"%s animation transition completed", __func__);
        }];
    }
}



@end
