//
//  czzTextViewHeightCalculator.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzTextViewHeightCalculator.h"
#import "czzSettingsCentre.h"

@implementation czzTextViewHeightCalculator

+(CGFloat)calculatePerfectHeightForContent:(NSAttributedString *)content inView:(UIView *)view hasImage:(BOOL)has{
    CGFloat preferHeight = 44;
    @autoreleasepool {
        UITextView *newHiddenTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width, 1)];
        newHiddenTextView.hidden = YES;
        [view addSubview:newHiddenTextView];
        newHiddenTextView.attributedText = content;
        newHiddenTextView.font = [[czzSettingsCentre sharedInstance] contentFont];
        preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(newHiddenTextView.frame.size.width, MAXFLOAT)].height + 20;
        [newHiddenTextView removeFromSuperview];
    }
    
    if (has) {
        if ([[czzSettingsCentre sharedInstance] userDefShouldUseBigImage])
            preferHeight += view.frame.size.width / 3;
        else
            preferHeight += IMAGE_HEIGHT;
    }
    
    return preferHeight;
}

@end
