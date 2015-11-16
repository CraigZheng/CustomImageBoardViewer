//
//  czzModalViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 16/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzModalViewController.h"

@implementation czzModalViewController

- (void)modalShow {
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self.modalAnimator = [czzFadeInOutModalAnimator new];
    [[UIApplication rootViewController] presentViewController:self animated:YES completion:nil];
}

@end
