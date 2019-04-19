//
//  czzModalViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 16/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzModalViewController.h"

@interface czzModalViewController()
@property (nonatomic, strong) UIGestureRecognizer *fullscreenGestureRecognizer;
@end

@implementation czzModalViewController

#pragma mark - init
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _dismissOnTap = YES;
    _fullscreenGestureRecognizer = [UITapGestureRecognizer new];
    [_fullscreenGestureRecognizer addTarget:self action:@selector(tapOnViewAction:)];
}

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.dismissOnTap) {
        [self.view addGestureRecognizer:self.fullscreenGestureRecognizer];
    }
}

- (void)setDismissOnTap:(BOOL)dismissOnTap {
    _dismissOnTap = dismissOnTap;
    self.fullscreenGestureRecognizer.enabled = dismissOnTap;
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
