//
//  UIViewController+Util.m
//  CustomImageBoardViewer
//
//  Created by Craig on 27/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "UIViewController+Util.h"

static NSInteger const progressBarViewTag = 123526475;

@implementation UIViewController (Util)

/**
 detect if being presented as a modal view,  copied from
 http://stackoverflow.com/questions/2798653/is-it-possible-to-determine-whether-viewcontroller-is-presented-as-modal/16764496#16764496
 */
- (BOOL)isModal {
    BOOL result = [self _isModal:self];
    if (self.parentViewController)
        result = [self _isModal:self.parentViewController];
    return result;
}

- (BOOL)_isModal:(UIViewController*)viewController {
    BOOL result = NO;
    if (viewController.presentingViewController.presentedViewController == viewController ||
        (viewController.navigationController != nil && viewController.navigationController.presentingViewController.presentedViewController == viewController.navigationController) ||
        (viewController.tabBarController != nil && [viewController.tabBarController.presentingViewController isKindOfClass:[UITabBarController class]])) {
        result = YES;
    }
    
    return result;
}

- (BOOL)isPresented {
    return self.isViewLoaded && self.view.window;
}

#pragma mark - Show loading.

- (void)startLoading {
    [self.progressView startAnimating];
}

- (void)stopLoading {
    [self.progressView stopAnimating];
}

- (void)showWarning {
    [self.progressView showWarning];
}

- (GSIndeterminateProgressView *)progressView {
    GSIndeterminateProgressView *barView = [self.view viewWithTag:progressBarViewTag];
    // If self.view does not containt a subview with the given tag.
    if (!barView) {
        barView = [[GSIndeterminateProgressView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        barView.tag = progressBarViewTag;
        [self.view addSubview:barView];
        [self.view bringSubviewToFront:barView];
        barView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [barView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [barView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [barView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
            [barView.heightAnchor constraintEqualToConstant:2]
        ]];
        [self.view layoutIfNeeded];
    }
    return barView;
}

@end
