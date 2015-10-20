//
//  czzThreadViewCellFooterView.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 3/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzThreadViewCellFooterView.h"

#import "UIView+MGBadgeView.h"

@interface czzThreadViewCellFooterView()

@property (weak, nonatomic) IBOutlet UILabel *sageLabel;
@property (weak, nonatomic) IBOutlet UILabel *lockedLabel;
@property (weak, nonatomic) IBOutlet UILabel *responseCountLabel;

@end

@implementation czzThreadViewCellFooterView

-(void)renderContent {
    self.sageLabel.hidden = self.lockedLabel.hidden = self.responseCountLabel.hidden = YES;
    if (self.myThread) {
        if (self.myThread.sage)
            self.sageLabel.hidden = NO;
        if (self.myThread.lock)
            self.lockedLabel.hidden = NO;
        if (self.myThread.responseCount) {
            // If should highlight response label, use the badgeView instead, which provides a nice looking badge view.
            self.responseCountLabel.hidden = NO;
            if (self.highlightResponse) {
                self.responseCountLabel.badgeView.badgeValue = self.myThread.responseCount;
                self.responseCountLabel.badgeView.position = MGBadgePositionTopLeft;
                self.responseCountLabel.badgeView.badgeColor = [UIColor redColor];
                self.responseCountLabel.text = nil;
            } else {
                self.responseCountLabel.text = [NSString stringWithFormat:@"回应:%ld", (long)self.myThread.responseCount];
            }
        }
    }
}

#pragma mark - Setters

-(void)setMyThread:(czzThread *)myThread {
    _myThread = myThread;
    [self renderContent];
}

-(void)setHighlightResponse:(BOOL)highlightResponse {
    _highlightResponse = highlightResponse;
    [self renderContent];
}

@end
