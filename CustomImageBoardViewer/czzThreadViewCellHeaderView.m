//
//  czzThreadViewCellHeaderView.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 2/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzThreadViewCellHeaderView.h"

@interface czzThreadViewCellHeaderView()
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UILabel *posterLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation czzThreadViewCellHeaderView

#pragma mark - Setters

-(void)setMyThread:(czzThread *)myThread {
    _myThread = myThread;
    if (myThread) {
        self.idLabel.text = [NSString stringWithFormat:@"NO:%ld", (long)myThread.ID];
        NSMutableAttributedString *uidAttrString = [[NSMutableAttributedString alloc] initWithString:@"ID:"];
        if (myThread.UID)
            [uidAttrString appendAttributedString:myThread.UID];
        self.posterLabel.attributedText = uidAttrString;
        self.dateLabel.text = [self.dateFormatter stringFromDate:myThread.postDateTime];
        
        //highlight original poster
        if (self.shouldHighLight &&
            [myThread.UID.string isEqualToString: self.parentUID]) {
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
