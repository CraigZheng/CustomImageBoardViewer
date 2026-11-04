//
//  CPAutoFillView.m
//  CashByOptusPhone
//
//  Created by Craig on 8/05/2015.
//  Copyright (c) 2015 Singtel Optus Pty Ltd. All rights reserved.
//

#import "CPAutoFillView.h"

@implementation CPAutoFillView

- (void)didMoveToSuperview {
    if (self.superview) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [self.topAnchor constraintEqualToAnchor:self.superview.topAnchor],
            [self.bottomAnchor constraintEqualToAnchor:self.superview.bottomAnchor],
            [self.leadingAnchor constraintEqualToAnchor:self.superview.leadingAnchor],
            [self.trailingAnchor constraintEqualToAnchor:self.superview.trailingAnchor]
        ]];
    }
}
@end
