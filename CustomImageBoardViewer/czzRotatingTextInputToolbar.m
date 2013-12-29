//
//  czzRotatingTextInputToolbar.m
//  CustomImageBoardViewer
//
//  Created by Craig on 28/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzRotatingTextInputToolbar.h"

@implementation czzRotatingTextInputToolbar

- (void) layoutSubviews
{
    [super layoutSubviews];
    CGRect origFrame = self.frame;
    [self sizeToFit];
    CGRect newFrame = self.frame;
    newFrame.origin.y += origFrame.size.height - newFrame.size.height;
    newFrame.origin.x = 0;
    self.frame = newFrame;
    
}
@end
