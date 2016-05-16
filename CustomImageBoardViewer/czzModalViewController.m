//
//  czzModalViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 16/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzModalViewController.h"

@implementation czzModalViewController

#pragma mark - init
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Default to YES
        self.dismissOnTap = YES;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Default to YES
        self.dismissOnTap = YES;
    }
    return self;
}

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.dismissOnTap) {
        UITapGestureRecognizer *tapOnViewGestureRecognizer = [UITapGestureRecognizer new];
        [tapOnViewGestureRecognizer addTarget:self action:@selector(tapOnViewAction:)];
        [self.view addGestureRecognizer:tapOnViewGestureRecognizer];
    }
}

- (void)tapOnViewAction:(UITapGestureRecognizer *)sender {
    if (self.dismissOnTap) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)modalShow {
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self.modalAnimator = [czzFadeInOutModalAnimator new];
    [[UIApplication rootViewController] presentViewController:self animated:YES completion:nil];
}

@end
