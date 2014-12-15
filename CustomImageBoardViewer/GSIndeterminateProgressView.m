//
//  GSIndeterminateProgressView.m
//  Neverlate
//
//  Created by Endika Gutiérrez Salas on 15/11/13.
//  Copyright (c) 2013 Endika Gutiérrez Salas. All rights reserved.
//

#import "GSIndeterminateProgressView.h"
@interface GSIndeterminateProgressView()
@property CGFloat CHUNK_WIDTH;
@property NSArray *colours;
@property NSUInteger colourIndex;
@end

@implementation GSIndeterminateProgressView
@synthesize CHUNK_WIDTH;
@synthesize colourIndex;
@synthesize colours;

@synthesize isAnimating = _isAnimating;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;

        self.trackTintColor = [UIColor clearColor];
        self.progressTintColor = [UIColor blueColor];

        self.hidesWhenStopped = YES;
        self.hidden = YES;
        
        CHUNK_WIDTH = MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        colourIndex = 0;
        colours = @[[UIColor cyanColor], [UIColor magentaColor], [UIColor yellowColor]];//, [UIColor blackColor]];
    }
    return self;
}

- (void)setTrackTintColor:(UIColor *)trackTintColor
{
    _trackTintColor = trackTintColor;
    self.backgroundColor = trackTintColor;
}

- (void)setProgressTintColor:(UIColor *)progressTintColor
{
//    _progressTintColor = progressTintColor;
//    for (UIView *v in self.progressChunks) {
//        v.backgroundColor = progressTintColor;
//    }
}

- (void)startAnimating
{
    if (_isAnimating) return;
    _isAnimating = YES;

    self.hidden = NO;
    
    self.progressChunks = @[[[UIView alloc] initWithFrame:CGRectMake(-CHUNK_WIDTH, 0, CHUNK_WIDTH, self.frame.size.height)],
                            [[UIView alloc] initWithFrame:CGRectMake(-CHUNK_WIDTH, 0, CHUNK_WIDTH, self.frame.size.height)],
                            [[UIView alloc] initWithFrame:CGRectMake(-CHUNK_WIDTH, 0, CHUNK_WIDTH, self.frame.size.height)]];

    NSTimeInterval delay = 0;
    for (UIView *v in self.progressChunks) {
        v.backgroundColor = self.progressTintColor;
        [self addSubview:v];

        [self animateProgressChunk:v delay:(delay += 0.25)];
    }
}

- (void)stopAnimating
{
    if (!_isAnimating) return;
    _isAnimating = NO;

    self.hidden = self.hidesWhenStopped;

    for (UIView *v in self.progressChunks) {
        [v removeFromSuperview];
    }

    self.progressChunks = nil;
}

-(UIColor*)progressTintColor {
    UIColor *tintColour = [colours objectAtIndex:colourIndex++];
    if (colourIndex >= colours.count)
        colourIndex = 0;
    return tintColour;
}

- (void)animateProgressChunk:(UIView *)chunk delay:(NSTimeInterval)delay
{
    [UIView animateWithDuration:1.0 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        chunk.backgroundColor = self.progressTintColor;
        CGRect chuckFrame = chunk.frame;
        chuckFrame.origin.x = self.frame.size.width;
        chunk.frame = chuckFrame;
    } completion:^(BOOL finished) {
        CGRect chuckFrame = chunk.frame;
        chuckFrame.origin.x = -CHUNK_WIDTH;
        chunk.frame = chuckFrame;
        if (finished)
            [self animateProgressChunk:chunk delay:0.75];
    }];
}

@end
