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

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.contentView.backgroundColor = [settingCentre viewBackgroundColour];
    NSLayoutConstraint *minHeight = [self.contentView.heightAnchor constraintGreaterThanOrEqualToConstant:44];
    minHeight.priority = UILayoutPriorityDefaultHigh;
    minHeight.active = YES;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self commonInit];
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
