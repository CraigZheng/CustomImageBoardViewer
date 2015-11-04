//
//  czzThreadViewCellFooterView.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 3/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzThreadViewCellFooterView.h"

@interface czzThreadViewCellFooterView()

@property (weak, nonatomic) IBOutlet UILabel *sageLabel;
@property (weak, nonatomic) IBOutlet UILabel *lockedLabel;
@property (weak, nonatomic) IBOutlet UILabel *responseCountLabel;

@end

@implementation czzThreadViewCellFooterView

#pragma mark - Setters

-(void)setMyThread:(czzThread *)myThread {
    _myThread = myThread;
    self.sageLabel.hidden = self.lockedLabel.hidden = self.responseCountLabel.hidden = YES;
    if (myThread) {
        if (myThread.sage)
            self.sageLabel.hidden = NO;
        if (myThread.lock)
            self.lockedLabel.hidden = NO;
        if (myThread.responseCount) {
            self.responseCountLabel.text = [NSString stringWithFormat:@"回应:%ld", (long)myThread.responseCount];
            self.responseCountLabel.hidden = NO;
        }
    }
}

-(BOOL)isHidden {
    return self.sageLabel.hidden == self.lockedLabel.hidden == self.responseCountLabel.hidden == YES;
}

@end
