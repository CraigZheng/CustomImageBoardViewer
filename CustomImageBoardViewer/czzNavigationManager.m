//
//  czzNavigationManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/07/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzNavigationManager.h"
#import "czzHomeViewController.h"
#import "czzThreadViewController.h"


@implementation czzNavigationManager
-(void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self.delegate navigationManager:self wantsToPushViewController:viewController animated:animated];
}

-(void)popViewControllerAnimated:(BOOL)animted {
    [self.delegate navigationManager:self wantsToPopViewControllerAnimated:animted];
}

-(void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self.delegate navigationManager:self wantsToPopToViewController:viewController animated:animated];
}

- (void)setViewController:(NSArray *)viewControllers animated:(BOOL)animated {
    [self.delegate navigationManager:self wantsToSetViewController:viewControllers animated:animated];
}

#pragma mark - UINavigationControllerDelegate
-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.isInTransition = YES;
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 0.29 * NSEC_PER_SEC);
    // After a certain period of time, set the isInTransition back to NO. This prevents the error that triggerd by user partially return to the previous view controller.
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        self.isInTransition = NO;
    });
}

-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.isInTransition = NO;
    @try {
        if (self.pushAnimationCompletionHandler) {
            self.pushAnimationCompletionHandler();
            self.pushAnimationCompletionHandler = nil;
        }
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    
    // Reload animating progress view.
    if ([viewController isKindOfClass:[czzHomeViewController class]] ||
        [viewController isKindOfClass:[czzThreadViewController class]]) {
        czzHomeViewModelManager *viewModelManager = [viewController performSelector:@selector(viewModelManager)];
        if ([viewModelManager isDownloading]) {
            [self.delegate.progressView startAnimating];
        } else {
            [self.delegate.progressView stopAnimating];
        }
    }
}

+(instancetype)sharedManager {
    static dispatch_once_t once_token;
    static id sharedManager;
    if (!sharedManager) {
        dispatch_once(&once_token, ^{
            sharedManager = [czzNavigationManager new];
        });
    }
    return sharedManager;
}
@end
