//
//  czzThreadViewCellHeaderView.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 2/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzThreadViewCellHeaderView.h"
#import "czzSettingsCentre.h"
#import "UIColor+Hexadecimal.h"
#import "CustomImageBoardViewer-Swift.h" // For RoundCornerBorderedButton if needed

#define RGBCOLOR(r,g,b)[UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define brownColour RGBCOLOR(168, 123, 65)

@interface czzThreadViewCellHeaderView()
@property (strong, nonatomic) UILabel *idLabel;
@property (strong, nonatomic) UILabel *posterLabel;
@property (strong, nonatomic) UILabel *dateLabel;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *nicknameLabel;
@property (strong, nonatomic) UIImageView *flagImageView;
@property (strong, nonatomic) NSLayoutConstraint *dateBottomPaddingConstraint;
@property (strong, nonatomic) UIView *topSeparator;
@property (strong, nonatomic) UIView *headerContainerView;
@property (strong, nonatomic) UIStackView *headerStackView;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation czzThreadViewCellHeaderView

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
    
    _headerButton = [UIButton buttonWithType:UIButtonTypeSystem]; // Using system for now, originally RoundCornerBorderedButton
    _headerButton.translatesAutoresizingMaskIntoConstraints = NO;
    _headerButton.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:173.0/255.0 blue:44.0/255.0 alpha:1.0]; // FFAD2C
    [_headerButton setTitle:@"点击以加载" forState:UIControlStateNormal];
    [_headerButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    _headerButton.layer.cornerRadius = 4.0;
    
    _headerContainerView = [[UIView alloc] init];
    _headerContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [_headerContainerView addSubview:_headerButton];
    
    _headerStackView = [[UIStackView alloc] initWithArrangedSubviews:@[_headerContainerView]];
    _headerStackView.translatesAutoresizingMaskIntoConstraints = NO;
    _headerStackView.axis = UILayoutConstraintAxisVertical;
    _headerStackView.spacing = 8;
    [self addSubview:_headerStackView];
    
    _topSeparator = [[UIView alloc] init];
    _topSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    _topSeparator.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self addSubview:_topSeparator];
    
    _idLabel = [self createLabelWithColor:brownColour weight:UIFontWeightMedium size:14];
    [self addSubview:_idLabel];
    
    _posterLabel = [self createLabelWithColor:brownColour weight:UIFontWeightMedium size:14];
    [self addSubview:_posterLabel];
    
    _flagImageView = [[UIImageView alloc] init];
    _flagImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _flagImageView.image = [[UIImage imageNamed:@"flag"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self addSubview:_flagImageView];
    
    _dateLabel = [self createLabelWithColor:brownColour weight:UIFontWeightMedium size:14];
    [_dateLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self addSubview:_dateLabel];
    
    UIColor *grayColor = [UIColor colorWithRed:0.435 green:0.443 blue:0.475 alpha:1.0];
    _titleLabel = [self createLabelWithColor:grayColor weight:UIFontWeightMedium size:14];
    _titleLabel.numberOfLines = 2;
    [self addSubview:_titleLabel];
    
    _nameLabel = [self createLabelWithColor:grayColor weight:UIFontWeightMedium size:14];
    _nameLabel.numberOfLines = 2;
    [self addSubview:_nameLabel];
    
    _nicknameLabel = [self createLabelWithColor:grayColor weight:UIFontWeightMedium size:14];
    _nicknameLabel.numberOfLines = 2;
    [self addSubview:_nicknameLabel];
    
    _headerButtonContainerViewHeightConstraint = [_headerContainerView.heightAnchor constraintEqualToConstant:0];
    
    _dateBottomPaddingConstraint = [self.bottomAnchor constraintGreaterThanOrEqualToAnchor:_dateLabel.bottomAnchor constant:4];
    _dateBottomPaddingConstraint.priority = UILayoutPriorityRequired;
    
    [NSLayoutConstraint activateConstraints:@[
        [_headerStackView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_headerStackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
        [_headerStackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
        
        [_headerButton.topAnchor constraintEqualToAnchor:_headerContainerView.topAnchor constant:8],
        [_headerButton.bottomAnchor constraintEqualToAnchor:_headerContainerView.bottomAnchor constant:-8],
        [_headerButton.leadingAnchor constraintEqualToAnchor:_headerContainerView.leadingAnchor],
        [_headerButton.trailingAnchor constraintEqualToAnchor:_headerContainerView.trailingAnchor],
        _headerButtonContainerViewHeightConstraint,
        
        [_topSeparator.topAnchor constraintEqualToAnchor:_headerStackView.bottomAnchor],
        [_topSeparator.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_topSeparator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_topSeparator.heightAnchor constraintEqualToConstant:1],
        
        [_idLabel.topAnchor constraintEqualToAnchor:_headerStackView.bottomAnchor constant:8],
        [_idLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        
        [_posterLabel.centerYAnchor constraintEqualToAnchor:_idLabel.centerYAnchor],
        [_posterLabel.leadingAnchor constraintEqualToAnchor:_idLabel.trailingAnchor constant:8],
        [_posterLabel.widthAnchor constraintLessThanOrEqualToConstant:100],
        
        [_flagImageView.centerYAnchor constraintEqualToAnchor:_posterLabel.centerYAnchor],
        [_flagImageView.leadingAnchor constraintEqualToAnchor:_posterLabel.trailingAnchor constant:8],
        [_flagImageView.heightAnchor constraintEqualToConstant:15],
        [_flagImageView.widthAnchor constraintEqualToConstant:15],
        
        [_dateLabel.centerYAnchor constraintEqualToAnchor:_flagImageView.centerYAnchor],
        [_dateLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_dateLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:_flagImageView.trailingAnchor constant:4],
        
        [_titleLabel.topAnchor constraintEqualToAnchor:_dateLabel.bottomAnchor constant:4],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        
        [_nameLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor],
        [_nameLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_nameLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        
        [_nicknameLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor],
        [_nicknameLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_nicknameLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        
        [self.bottomAnchor constraintGreaterThanOrEqualToAnchor:_nicknameLabel.bottomAnchor],
        _dateBottomPaddingConstraint
    ]];
}

- (UILabel *)createLabelWithColor:(UIColor *)color weight:(UIFontWeight)weight size:(CGFloat)size {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:size weight:weight];
    label.textColor = color;
    label.backgroundColor = [UIColor clearColor];
    return label;
}

- (void)layoutSubviews {
  self.topSeparator.hidden = self.headerButton.isHidden;
  [super layoutSubviews];
  self.headerButton.backgroundColor = self.headerButton.isEnabled ? [UIColor colorWithHex:@"FFAD2C"] : [UIColor lightGrayColor];
  [self.headerButton setTitleColor:self.headerButton.isEnabled ? [UIColor darkGrayColor] : [UIColor whiteColor]
                          forState:UIControlStateNormal];
}

#pragma mark - Setters

-(void)setThread:(czzThread *)myThread {
    _thread = myThread;
    if (myThread) {
        self.idLabel.text = [NSString stringWithFormat:@"%ld", (long)myThread.ID];
        self.posterLabel.attributedText = nil;
        self.posterLabel.text = myThread.UID;
        self.titleLabel.text = [myThread.title isEqualToString:settingCentre.empty_title] ? nil : [NSString stringWithFormat:@"标题: %@", myThread.title];
        self.nameLabel.text = [myThread.name isEqualToString:settingCentre.empty_username] ? nil : [NSString stringWithFormat:@"用户: %@", myThread.name];
        self.nicknameLabel.text = self.nickname.length ? [NSString stringWithFormat:@"昵称: %@", self.nickname] : nil;
        
        self.posterLabel.textColor = myThread.admin ? [UIColor redColor] : brownColour;
        self.dateLabel.text = [self.dateFormatter stringFromDate:myThread.postDateTime];
        
        BOOL hideAdditionalFields = !self.titleLabel.text && !self.nameLabel.text && !self.nicknameLabel.text;
        self.dateBottomPaddingConstraint.priority = hideAdditionalFields ? 999 : 1;
      
        if ([myThread.UID isEqualToString: self.parentUID] || myThread.admin) {
            self.posterLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        } else {
            self.posterLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        }
    }
}

- (void)setHighlightColour:(UIColor *)highlightColour {
    if (!highlightColour) {
        self.flagImageView.hidden = YES;
    } else {
        self.flagImageView.hidden = NO;
        self.flagImageView.tintColor = highlightColour;
    }
}

- (UIColor *)highlightColour {
    return self.flagImageView.tintColor;
}

#pragma mark - Getters

-(NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return _dateFormatter;
}

@end