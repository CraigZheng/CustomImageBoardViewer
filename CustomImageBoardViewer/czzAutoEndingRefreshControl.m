//
//  czzAutoEndingRefreshControl.m
//  CustomImageBoardViewer
//
//  Created by Craig on 5/04/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzAutoEndingRefreshControl.h"

@implementation czzAutoEndingRefreshControl

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    [super sendAction:action to:target forEvent:event];
    __weak typeof(self) weakSelf = self;
    // After action is sent, end refreshing with a delay.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf endRefreshing];
    });
}

@end
