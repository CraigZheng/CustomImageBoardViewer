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
@property NSMutableArray *stripViews;
@end

@implementation GSIndeterminateProgressView
@synthesize CHUNK_WIDTH;
@synthesize colourIndex;
@synthesize colours;
@synthesize stripViews;

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
        
        stripViews = [NSMutableArray new];
    }
    return self;
}

- (void)setTrackTintColor:(UIColor *)trackTintColor
{
    _trackTintColor = trackTintColor;
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
    self.backgroundColor = self.trackTintColor;

    self.progressChunks = @[[[UIView alloc] initWithFrame:CGRectMake(-CHUNK_WIDTH, 0, CHUNK_WIDTH, self.frame.size.height)],
                            [[UIView alloc] initWithFrame:CGRectMake(-CHUNK_WIDTH, 0, CHUNK_WIDTH, self.frame.size.height)],
                            [[UIView alloc] initWithFrame:CGRectMake(-CHUNK_WIDTH, 0, CHUNK_WIDTH, self.frame.size.height)]];

    NSTimeInterval delay = 0;
    for (UIView *v in self.progressChunks) {
        v.backgroundColor = self.progressTintColor;
        [self addSubview:v];

        [self animateProgressChunk:v delay:(delay += 0.25)];
    }
    
    for (UIView *stripView in stripViews) {
        [stripView removeFromSuperview];
    }
    [stripViews removeAllObjects];
}

- (void)stopAnimating
{
    if (!_isAnimating) return;
    _isAnimating = NO;

    self.hidden = self.hidesWhenStopped;

    for (UIView *v in self.progressChunks) {
        [v removeFromSuperview];
    }
    
    for (UIView *stripView in stripViews) {
        [stripView removeFromSuperview];
    }
    [stripViews removeAllObjects];

    self.progressChunks = nil;
}

-(void)showWarning {
    _isAnimating = NO;
    self.hidden = NO;
    
    static CGFloat warningChunkWidth = 20.;
    NSInteger count = CHUNK_WIDTH / warningChunkWidth;
    for (NSInteger i = 0; i <= count; i++) {
        UIView *stripView = [[UIView alloc] initWithFrame:CGRectMake(i * 2 * warningChunkWidth, 0, warningChunkWidth, self.frame.size.height)];
        stripView.backgroundColor = [UIColor colorWithRed:220/255. green:20/255. blue:60/255. alpha:1.0]; //220	20	60
        [stripViews addObject:stripView];
        [self addSubview:stripView];
    }
    self.backgroundColor = [UIColor whiteColor];
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
