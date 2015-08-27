//
//  czzNavigationViewModelManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/07/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzNavigationViewModelManager.h"

@implementation czzNavigationViewModelManager
-(void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self.delegate viewModelManager:self wantsToPushViewController:viewController animated:animated];
}

-(void)popViewControllerAnimated:(BOOL)animted {
    [self.delegate viewModelManager:self wantsToPopViewControllerAnimated:animted];
}

-(void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self.delegate viewModelManager:self wantsToPopToViewController:viewController animated:animated];
}

- (void)setViewController:(NSArray *)viewControllers animated:(BOOL)animated {
    [self.delegate viewModelManager:self wantsToSetViewController:viewControllers animated:animated];
}

#pragma mark - UINavigationControllerDelegate
-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.isInTransition = YES;
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
}

+(instancetype)sharedManager {
    static dispatch_once_t once_token;
    static id sharedManager;
    if (!sharedManager) {
        dispatch_once(&once_token, ^{
            sharedManager = [czzNavigationViewModelManager new];
        });
    }
    return sharedManager;
}
@end
