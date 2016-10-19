//
//  czzThreadViewCellHeaderView.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 2/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzThreadViewCellHeaderView.h"

#import "czzSettingsCentre.h"

#define RGBCOLOR(r,g,b)[UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define brownColour RGBCOLOR(168, 123, 65)

@interface czzThreadViewCellHeaderView()
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UILabel *posterLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end
// Default colour 168	123	65
@implementation czzThreadViewCellHeaderView

#pragma mark - Setters

-(void)setThread:(czzThread *)myThread {
    _thread = myThread;
    if (myThread) {
        self.idLabel.text = [NSString stringWithFormat:@"%ld", (long)myThread.ID];
        self.posterLabel.text = myThread.UID;
        // Hide title container if there is not a title to show.
        if ([myThread.title isEqualToString:settingCentre.empty_title]) {
            self.titleLabel.text = nil;
        } else {
            self.titleLabel.text = [NSString stringWithFormat:@"标题: %@", myThread.title];
        }
        if ([myThread.name isEqualToString:settingCentre.empty_username]) {
            // No name to show.
            self.nameLabel.text = nil;
        } else {
            // If there is a name to show...
            self.nameLabel.text = [NSString stringWithFormat:@"用户: %@", myThread.name];
        }
        // If admin, highlight.
        if (myThread.admin) {
            self.posterLabel.textColor = [UIColor redColor];
        } else {
            self.posterLabel.textColor = brownColour;
        }
        self.dateLabel.text = [self.dateFormatter stringFromDate:myThread.postDateTime];
        
        //highlight original poster
        if ([myThread.UID isEqualToString: self.parentUID]) {
            NSMutableAttributedString *opAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.posterLabel.attributedText];
            [opAttributedString addAttributes:@{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)} range:NSMakeRange(0, opAttributedString.length)];
            self.posterLabel.attributedText = opAttributedString;
        }

    }
}

#pragma mark - Getters

-(NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"hh:mma, yyyy-MM-dd";
    }
    return _dateFormatter;
}

/*
 idLabel.text = [NSString stringWithFormat:@"NO:%ld", (long)myThread.ID];
 
 NSMutableAttributedString *uidAttrString = [[NSMutableAttributedString alloc] initWithString:@"ID:"];
 if (myThread.UID)
 [uidAttrString appendAttributedString:myThread.UID];
 posterLabel.attributedText = uidAttrString;
 dateLabel.text = [self.dateFormatter stringFromDate:myThread.postDateTime];

 */


@end
