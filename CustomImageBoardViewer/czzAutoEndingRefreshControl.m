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
    // After action is sent, end refreshing immediately.
    [[NSOperationQueue currentQueue] addOperationWithBlock:^{
        [weakSelf endRefreshing];
    }];
}

@end
