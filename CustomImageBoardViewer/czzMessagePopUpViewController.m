//
//  czzMessagePopUpViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/01/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzMessagePopUpViewController.h"
#import "czzSettingsCentre.h"

@interface czzMessagePopUpViewController ()
@property (strong, nonatomic) UIView *containerView;
@end

@implementation czzMessagePopUpViewController
@synthesize messageContentLabel, messageImageView, messageToShow, imageToShow;

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = settingCentre.transparentBackgroundColour;
    
    _containerView = [[UIView alloc] init];
    _containerView.translatesAutoresizingMaskIntoConstraints = NO;
    _containerView.backgroundColor = [UIColor colorWithWhite:0.667 alpha:0.9];
    _containerView.layer.cornerRadius = 10.0;
    _containerView.clipsToBounds = YES;
    [self.view addSubview:_containerView];
    
    messageImageView = [[UIImageView alloc] init];
    messageImageView.translatesAutoresizingMaskIntoConstraints = NO;
    messageImageView.contentMode = UIViewContentModeScaleAspectFit;
    [_containerView addSubview:messageImageView];
    
    messageContentLabel = [[UILabel alloc] init];
    messageContentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    messageContentLabel.font = [UIFont systemFontOfSize:14];
    messageContentLabel.textColor = [UIColor colorWithRed:0.6 green:0.4 blue:0.2 alpha:1.0];
    messageContentLabel.textAlignment = NSTextAlignmentCenter;
    [_containerView addSubview:messageContentLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [_containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_containerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_containerView.widthAnchor constraintEqualToConstant:160],
        [_containerView.heightAnchor constraintEqualToConstant:132],
        
        [messageImageView.centerXAnchor constraintEqualToAnchor:_containerView.centerXAnchor],
        [messageImageView.centerYAnchor constraintEqualToAnchor:_containerView.centerYAnchor],
        [messageImageView.widthAnchor constraintEqualToConstant:80],
        [messageImageView.heightAnchor constraintEqualToConstant:80],
        
        [messageContentLabel.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor constant:8],
        [messageContentLabel.trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor constant:-8],
        [messageContentLabel.bottomAnchor constraintEqualToAnchor:_containerView.bottomAnchor constant:-8]
    ]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = settingCentre.transparentBackgroundColour;
}

- (void)modalShow {
    if (messageToShow) {
        messageContentLabel.text = messageToShow;
    }
    if (imageToShow) {
        messageImageView.image = imageToShow;
    }
    [super modalShow];
}

+ (instancetype)new {
    return [[self alloc] init];
}

@end
