//
//  CPAutoFillView.m
//  CashByOptusPhone
//
//  Created by Craig on 8/05/2015.
//  Copyright (c) 2015 Singtel Optus Pty Ltd. All rights reserved.
//

#import "CPAutoFillView.h"
#import "PureLayout.h"

@implementation CPAutoFillView

- (void)didMoveToSuperview {
    if (self.superview) {
        [self autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }
}
@end
