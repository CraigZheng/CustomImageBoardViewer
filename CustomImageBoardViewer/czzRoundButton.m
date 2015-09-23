//
//  czzRoundButton.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 23/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzRoundButton.h"

@implementation czzRoundButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    [self setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    self.titleLabel.font = [UIFont systemFontOfSize:11];
    self.backgroundColor = [UIColor whiteColor];
    // Get the shortest side, and divide by 2, use this value as the corner radius = a round button!
    self.layer.cornerRadius = MIN(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)) / 2;
}

@end
