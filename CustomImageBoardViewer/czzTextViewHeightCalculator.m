//
//  czzTextViewHeightCalculator.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzTextViewHeightCalculator.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzSettingsCentre.h"
#import "czzAppDelegate.h"

@implementation czzTextViewHeightCalculator

+(CGFloat)calculatePerfectHeightForThreadContent:(czzThread *)thread inView:(UIView *)view forWidth:(CGFloat)width hasImage:(BOOL)has withExtra:(BOOL)extra{
    CGFloat preferHeight = 44;
    
    @autoreleasepool {
        UITextView *newHiddenTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width, 1)];
        newHiddenTextView.hidden = YES;
        [view addSubview:newHiddenTextView];
        newHiddenTextView.attributedText = thread.content;
        newHiddenTextView.font = [[czzSettingsCentre sharedInstance] contentFont];
        preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(width, MAXFLOAT)].height + 35;
        [newHiddenTextView removeFromSuperview];
    }
    
    if (has) {
        if ([[czzSettingsCentre sharedInstance] userDefShouldUseBigImage])
        {
            return preferHeight += 280;
        }
        else
            preferHeight += IMAGE_HEIGHT;
    }
    preferHeight += THREAD_VIEW_CELL_MARGIN;
    return preferHeight;
}

+(CGFloat)calculatePerfectHeightForThreadContent:(czzThread *)thread inView:(UIView *)view hasImage:(BOOL)has{
    return [self calculatePerfectHeightForThreadContent:thread inView:view forWidth:view.frame.size.width hasImage:has withExtra:NO];
}

@end
