//
//  czzNoSelectionTextView.m
//  CustomImageBoardViewer
//
//  Created by Craig on 31/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzNoSelectionTextView.h"

@implementation czzNoSelectionTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (BOOL)canBecomeFirstResponder {
    return NO;
}

@end
