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

@property (strong, nonatomic) UILabel *sageLabel;
@property (strong, nonatomic) UILabel *lockedLabel;
@property (strong, nonatomic) UILabel *responseCountLabel;
@property (strong, nonatomic) UILabel *forumLabel;
@property (strong, nonatomic) UIImageView *chatImageView;
@property (strong, nonatomic) UIView *bottomSeparator;
@property (strong, nonatomic) NSLayoutConstraint *bottomSeparatorVerticalSpacingConstraint;

@end

@implementation czzThreadViewCellFooterView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.backgroundColor = [UIColor clearColor];
    
    UIColor *brownColor = [UIColor colorWithRed:153.0/255.0 green:102.0/255.0 blue:51.0/255.0 alpha:1.0];
    UIColor *redColor = [UIColor colorWithRed:204.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:1.0];
    UIFont *labelFont = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    
    _forumLabel = [[UILabel alloc] init];
    _forumLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _forumLabel.font = labelFont;
    _forumLabel.textColor = redColor;
    [self addSubview:_forumLabel];
    
    _sageLabel = [[UILabel alloc] init];
    _sageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _sageLabel.font = labelFont;
    _sageLabel.textColor = redColor;
    _sageLabel.text = @"SAGE";
    [self addSubview:_sageLabel];
    
    _lockedLabel = [[UILabel alloc] init];
    _lockedLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _lockedLabel.font = labelFont;
    _lockedLabel.textColor = redColor;
    _lockedLabel.text = @"已锁";
    [self addSubview:_lockedLabel];
    
    _responseCountLabel = [[UILabel alloc] init];
    _responseCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _responseCountLabel.font = labelFont;
    _responseCountLabel.textColor = brownColor;
    [self addSubview:_responseCountLabel];
    
    _chatImageView = [[UIImageView alloc] init];
    _chatImageView.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *chatImage = [[UIImage imageNamed:@"chat.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _chatImageView.image = chatImage;
    _chatImageView.tintColor = [UIColor colorWithRed:170.0/255.0 green:170.0/255.0 blue:170.0/255.0 alpha:1.0];
    [self addSubview:_chatImageView];
    
    _bottomSeparator = [[UIView alloc] init];
    _bottomSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomSeparator.backgroundColor = [UIColor groupTableViewBackgroundColor];
    _bottomSeparator.hidden = YES;
    [self addSubview:_bottomSeparator];
    
    _bottomSeparatorVerticalSpacingConstraint = [_bottomSeparator.topAnchor constraintEqualToAnchor:self.topAnchor];
    _bottomSeparatorVerticalSpacingConstraint.priority = 250;
    
    NSLayoutConstraint *bottomSeparatorMarginConstraint = [_bottomSeparator.topAnchor constraintEqualToAnchor:_sageLabel.bottomAnchor constant:4];
    bottomSeparatorMarginConstraint.priority = UILayoutPriorityDefaultHigh; // 750
    
    [NSLayoutConstraint activateConstraints:@[
        [_forumLabel.centerYAnchor constraintEqualToAnchor:_sageLabel.centerYAnchor],
        [_forumLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
        
        [_sageLabel.leadingAnchor constraintEqualToAnchor:_forumLabel.trailingAnchor constant:8],
        
        [_lockedLabel.centerYAnchor constraintEqualToAnchor:_sageLabel.centerYAnchor],
        [_lockedLabel.leadingAnchor constraintEqualToAnchor:_sageLabel.trailingAnchor constant:8],
        
        [_responseCountLabel.centerYAnchor constraintEqualToAnchor:_lockedLabel.centerYAnchor],
        [_responseCountLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
        [_responseCountLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
        
        [_chatImageView.centerYAnchor constraintEqualToAnchor:_responseCountLabel.centerYAnchor],
        [_chatImageView.trailingAnchor constraintEqualToAnchor:_responseCountLabel.leadingAnchor constant:-4],
        [_chatImageView.widthAnchor constraintEqualToConstant:20],
        [_chatImageView.heightAnchor constraintEqualToConstant:20],
        
        _bottomSeparatorVerticalSpacingConstraint,
        bottomSeparatorMarginConstraint,
        [_bottomSeparator.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_bottomSeparator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_bottomSeparator.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_bottomSeparator.heightAnchor constraintEqualToConstant:2]
    ]];
}

#pragma mark - Setters

-(void)setThread:(czzThread *)myThread {
    _thread = myThread;
    self.chatImageView.hidden = self.sageLabel.hidden = self.lockedLabel.hidden = self.responseCountLabel.hidden = self.forumLabel.hidden = YES;
    if (myThread) {
        self.sageLabel.hidden = !myThread.sage;
        self.lockedLabel.hidden = !myThread.lock;
        if (myThread.responseCount) {
            self.responseCountLabel.text = [NSString stringWithFormat:@"%ld", (long)myThread.responseCount];
            self.chatImageView.hidden = self.responseCountLabel.hidden = NO;
        }
        if (myThread.fid) {
            [[czzForumManager sharedManager].forums enumerateObjectsUsingBlock:^(czzForum * _Nonnull forum, NSUInteger idx, BOOL * _Nonnull stop) {
                if (myThread.fid == forum.forumID) {
                    self.forumLabel.text = forum.name;
                    self.forumLabel.hidden = NO;
                    *stop = YES;
                }
            }];
        } else {
            self.forumLabel.text = nil;
            self.forumLabel.hidden = YES;
        }
    }
    if (self.sageLabel.hidden && self.lockedLabel.hidden && self.responseCountLabel.hidden && self.forumLabel.hidden) {
        self.bottomSeparatorVerticalSpacingConstraint.priority = 999;
    } else {
        self.bottomSeparatorVerticalSpacingConstraint.priority = 250;
    }
    [self setNeedsLayout];
}

@end