//
//  czzThreadTableViewCommandCellTableViewCell.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/06/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadTableViewCommandCellTableViewCell.h"
#import "czzSettingsCentre.h"

@interface czzThreadTableViewCommandCellTableViewCell ()
@end

@implementation czzThreadTableViewCommandCellTableViewCell

-(void)awakeFromNib {
    [super awakeFromNib];
    self.contentView.backgroundColor = [settingCentre viewBackgroundColour];
    NSLayoutConstraint *minHeight = [self.contentView.heightAnchor constraintGreaterThanOrEqualToConstant:44];
    minHeight.priority = UILayoutPriorityDefaultHigh;
    minHeight.active = YES;
}

#pragma mark - Setters
- (void)setCommandStatusViewController:(czzThreadViewCommandStatusCellViewController *)commandStatusViewController {
    if (self.contentView) {
        _commandStatusViewController = commandStatusViewController;
        for (UIView *subView in self.contentView.subviews) {
            [subView removeFromSuperview];
        }
        if (_commandStatusViewController.view) {
            _commandStatusViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
            [self.contentView addSubview:_commandStatusViewController.view];
            [NSLayoutConstraint activateConstraints:@[
                [_commandStatusViewController.view.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
                [_commandStatusViewController.view.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
                [_commandStatusViewController.view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
                [_commandStatusViewController.view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
            ]];
        }
    }
}
@end