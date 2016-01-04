//
//  czzThreadViewCellHeaderView.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 2/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzThreadViewCellHeaderView.h"

#define RGBCOLOR(r,g,b)[UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define brownColour RGBCOLOR(168, 123, 65)

@interface czzThreadViewCellHeaderView()
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UILabel *posterLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end
// Default colour 168	123	65
@implementation czzThreadViewCellHeaderView

#pragma mark - Setters

-(void)setMyThread:(czzThread *)myThread {
    _myThread = myThread;
    static UIColor *defaultTextColour;
    // Avoid repeatitve calculation.
    if (!defaultTextColour) {
        defaultTextColour = brownColour;
    }
    if (myThread) {
        self.idLabel.text = [NSString stringWithFormat:@"%ld", (long)myThread.ID];
        self.posterLabel.text = [NSString stringWithFormat:@"%@", myThread.UID];
        // If admin, highlight.
        if (myThread.admin) {
            self.posterLabel.textColor = [UIColor redColor];
        } else {
            self.posterLabel.textColor = defaultTextColour;
        }
        self.dateLabel.text = [self.dateFormatter stringFromDate:myThread.postDateTime];
        
        //highlight original poster
        if (self.shouldHighLight &&
            [myThread.UID isEqualToString: self.parentUID]) {
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
