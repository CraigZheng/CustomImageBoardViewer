//
//  czzCustomSlideAnimationViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 5/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzCustomSlideAnimationViewController.h"
#import "CPWearableViewCustomTransitioningAnimator.h"

@interface czzCustomSlideAnimationViewController () <UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate>
@property UIPercentDrivenInteractiveTransition *interactivePopTransition;
@end

@implementation czzCustomSlideAnimationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.modalTransitionStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self;
    
    self.interactivePopGestureRecognizer.enabled = NO;

    UIScreenEdgePanGestureRecognizer *popRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePopRecognizer:)];
    popRecognizer.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:popRecognizer];
//
//    self.interactivePopGestureRecognizer.delegate = self;
//    [self.interactivePopGestureRecognizer removeTarget:nil action:nil];
//    [self.interactivePopGestureRecognizer addTarget:self action:@selector(handlePopRecognizer:)];
}

#pragma mark - UIGestureRecognizer

- (void)handlePopRecognizer:(UIScreenEdgePanGestureRecognizer*)recognizer {
    // Calculate how far the user has dragged across the view
    CGFloat progress = [recognizer translationInView:self.view].x / (self.view.bounds.size.width * 1.0);
    progress = MIN(1.0, MAX(0.0, progress));
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // Create a interactive transition and pop the view controller
        self.interactivePopTransition = [[UIPercentDrivenInteractiveTransition alloc] init];
        self.isDismissing = YES;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        // Update the interactive transition's progress
        [self.interactivePopTransition updateInteractiveTransition:progress];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        // Finish or cancel the interactive transition
        if (progress > 0.5) {
            [self.interactivePopTransition finishInteractiveTransition];
        }
        else {
            self.isDismissing = NO;
            [self.interactivePopTransition cancelInteractiveTransition];
        }
        
        self.interactivePopTransition = nil;
    }
}


- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    // Check if this is for our custom transition
    return self.interactivePopTransition;
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


- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.interactivePopTransition;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.interactivePopTransition;
}



@end
