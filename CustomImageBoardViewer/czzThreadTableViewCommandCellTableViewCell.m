//
//  czzThreadTableViewCommandCellTableViewCell.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/06/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzThreadTableViewCommandCellTableViewCell.h"

@interface czzThreadTableViewCommandCellTableViewCell ()
@property (nonatomic, strong) czzThreadViewCommandStatusCellViewController *commandStatusViewController;
@end

@implementation czzThreadTableViewCommandCellTableViewCell

- (void)awakeFromNib {
}

#pragma mark - Getters
- (czzThreadViewCommandStatusCellViewController *)commandStatusViewController {
    if (!_commandStatusViewController && self.contentView) {
        _commandStatusViewController = [czzThreadViewCommandStatusCellViewController new];
        [self.contentView addSubview:_commandStatusViewController.view];
    }
    return _commandStatusViewController;
}

#pragma mark - Setters
- (void)setCellType:(czzThreadViewCommandStatusCellViewType)cellType {
    self.commandStatusViewController.cellType = cellType;
}
@end
