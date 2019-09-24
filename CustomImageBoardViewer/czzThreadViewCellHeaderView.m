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

#define RGBCOLOR(r,g,b)[UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define brownColour RGBCOLOR(168, 123, 65)

@interface czzThreadViewCellHeaderView()
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UILabel *posterLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *nicknameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *flagImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dateBottomPaddingConstraint;
@property (weak, nonatomic) IBOutlet UIView *topSeparator;
@property (weak, nonatomic) IBOutlet UIView *headerContainerView;
@property (weak, nonatomic) IBOutlet UIStackView *headerStackView;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end
// Default colour 168	123	65
@implementation czzThreadViewCellHeaderView

- (void)awakeFromNib {
  [super awakeFromNib];
  self.flagImageView.image = [[UIImage imageNamed:@"flag"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
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
        // Hide title container if there is not a title to show.
        self.titleLabel.text = [myThread.title isEqualToString:settingCentre.empty_title] ? nil : [NSString stringWithFormat:@"标题: %@", myThread.title];
        self.nameLabel.text = [myThread.name isEqualToString:settingCentre.empty_username] ? nil : [NSString stringWithFormat:@"用户: %@", myThread.name];
        self.nicknameLabel.text = self.nickname.length ? [NSString stringWithFormat:@"昵称: %@", self.nickname] : nil;
        // If admin, highlight.
        self.posterLabel.textColor = myThread.admin ? [UIColor redColor] : brownColour;
        self.dateLabel.text = [self.dateFormatter stringFromDate:myThread.postDateTime];
        // If all additional fields are hidden, make date label bottom padding active.
        BOOL hideAdditionalFields = !self.titleLabel.text && !self.nameLabel.text && !self.nicknameLabel.text;
        self.dateBottomPaddingConstraint.priority = hideAdditionalFields ? 999 : 1;
      
        //highlight original poster
        if ([myThread.UID isEqualToString: self.parentUID]) {
            NSMutableAttributedString *opAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.posterLabel.attributedText];
            [opAttributedString addAttributes:@{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)} range:NSMakeRange(0, opAttributedString.length)];
            self.posterLabel.attributedText = opAttributedString;
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
        _dateFormatter.dateFormat = @"hh:mma, yyyy-MM-dd";
    }
    return _dateFormatter;
}

@end
