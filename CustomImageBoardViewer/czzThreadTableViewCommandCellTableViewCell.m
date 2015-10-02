//
//  czzThreadTableViewCommandCellTableViewCell.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/06/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadTableViewCommandCellTableViewCell.h"

@interface czzThreadTableViewCommandCellTableViewCell ()
@end

@implementation czzThreadTableViewCommandCellTableViewCell

-(void)awakeFromNib {
    [super awakeFromNib];
    self.contentView.backgroundColor = [settingCentre viewBackgroundColour];
}

#pragma mark - Setters
- (void)setCommandStatusViewController:(czzThreadViewCommandStatusCellViewController *)commandStatusViewController {
    if (self.contentView) {
        _commandStatusViewController = commandStatusViewController;
        for (UIView *subView in self.contentView.subviews) {
            [subView removeFromSuperview];
        }
        [self.contentView addSubview:_commandStatusViewController.view];
    }
}
@end