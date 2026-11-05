//
//  czzEmojiCollectionViewCell.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 5/11/2026.
//  Copyright © 2026 Craig. All rights reserved.
//

#import "czzEmojiCollectionViewCell.h"

/// Insets between the label and the cell edges, matching the original nib.
static CGFloat const kEmojiLabelInset = 1;
static CGFloat const kEmojiLabelFontSize = 14;
static CGFloat const kEmojiLabelMinimumScaleFactor = 0.5;

@implementation czzEmojiCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
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
    self.backgroundColor = [UIColor whiteColor];

    _emojiLabel = [[UILabel alloc] init];
    _emojiLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _emojiLabel.numberOfLines = 0;
    _emojiLabel.lineBreakMode = NSLineBreakByCharWrapping;
    _emojiLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    _emojiLabel.minimumScaleFactor = kEmojiLabelMinimumScaleFactor;
    _emojiLabel.adjustsFontSizeToFitWidth = YES;
    _emojiLabel.font = [UIFont systemFontOfSize:kEmojiLabelFontSize];
    _emojiLabel.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.contentView addSubview:_emojiLabel];

    [NSLayoutConstraint activateConstraints:@[
        [_emojiLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:kEmojiLabelInset],
        [_emojiLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kEmojiLabelInset],
        [_emojiLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kEmojiLabelInset],
        [_emojiLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-kEmojiLabelInset]
    ]];
}

@end
