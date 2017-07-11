//
//  czzThreadViewCellFooterView.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 3/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzThreadViewCellFooterView.h"

#import "czzForum.h"
#import "czzForumManager.h"

@interface czzThreadViewCellFooterView()

@property (weak, nonatomic) IBOutlet UILabel *sageLabel;
@property (weak, nonatomic) IBOutlet UILabel *lockedLabel;
@property (weak, nonatomic) IBOutlet UILabel *responseCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *forumLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorVerticalSpacingConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *chatImageView;

@end

@implementation czzThreadViewCellFooterView

#pragma mark - Setters

- (void)awakeFromNib {
    [super awakeFromNib];
    UIImage *chatImage = [[UIImage imageNamed:@"chat.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.chatImageView.image = chatImage;
}

-(void)setThread:(czzThread *)myThread {
    _thread = myThread;
    self.chatImageView.hidden = self.sageLabel.hidden = self.lockedLabel.hidden = self.responseCountLabel.hidden = YES;
    if (myThread) {
        self.sageLabel.hidden = !myThread.sage;
        self.lockedLabel.hidden = !myThread.lock;
        if (myThread.responseCount) {
            self.responseCountLabel.text = [NSString stringWithFormat:@"%ld", (long)myThread.responseCount];
            self.chatImageView.hidden = self.responseCountLabel.hidden = NO;
        }
    }
    // If all elements are hidden, shrink the size of this view.
    if (self.sageLabel.hidden && self.lockedLabel.hidden && self.responseCountLabel.hidden) {
        self.bottomSeparatorVerticalSpacingConstraint.priority = 999;
    } else {
        self.bottomSeparatorVerticalSpacingConstraint.priority = 1;
    }
    [self setNeedsLayout];
}

@end
