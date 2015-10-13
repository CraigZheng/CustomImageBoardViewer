//
//  czzSlideUpModalAnimator.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 13/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzFadeInOutModalAnimator.h"

@implementation czzFadeInOutModalAnimator

#pragma mark - UIViewControllerAnimatedTransitioning

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.2;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];
    UIViewController *toVC = (UIViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromVC = (UIViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    toVC.view.frame = fromVC.view.frame = containerView.bounds;
    if (self.isDismissing) {
        fromVC.view.alpha = 1;
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                         animations:^{
                             fromVC.view.alpha = 0;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else {
        [containerView addSubview:toVC.view];
        
        toVC.view.alpha = 0;
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                         animations:^{
                             toVC.view.alpha = 1;
                         }
                         completion:^(BOOL finished) {
                             [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                         }];
    }
    
}

#pragma mark - UIViewControllerTransitioningDelegate

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [czzFadeInOutModalAnimator new];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    czzFadeInOutModalAnimator *animator = [czzFadeInOutModalAnimator new];
    animator.isDismissing = YES;
    return animator;
}


@end
