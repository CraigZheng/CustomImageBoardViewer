//
//  czzSlideUpModalAnimator.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 13/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzSlideUpModalAnimator.h"

@implementation czzSlideUpModalAnimator

#pragma mark - UIViewControllerAnimatedTransitioning

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *inView = [transitionContext containerView];
    UIViewController *toVC = (UIViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromVC = (UIViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    if (self.isDismissing) {
        [transitionContext completeTransition:YES];
    } else {
        [inView addSubview:toVC.view];
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        [toVC.view setFrame:CGRectMake(0, screenRect.size.height, fromVC.view.frame.size.width, fromVC.view.frame.size.height)];
        
        [UIView animateWithDuration:0.25f
                         animations:^{
                             
                             [toVC.view setFrame:CGRectMake(0, 0, fromVC.view.frame.size.width, fromVC.view.frame.size.height)];
                         }
                         completion:^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                         }];
    }
    
}

#pragma mark - UIViewControllerTransitioningDelegate

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [czzSlideUpModalAnimator new];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    czzSlideUpModalAnimator *animator = [czzSlideUpModalAnimator new];
    animator.isDismissing = YES;
    return animator;
}


@end
