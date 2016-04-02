//
//  GSIndeterminateProgressView.m
//  Neverlate
//
//  Created by Endika Gutiérrez Salas on 15/11/13.
//  Copyright (c) 2013 Endika Gutiérrez Salas. All rights reserved.
//

#import "GSIndeterminateProgressView.h"
#import <PureLayout/PureLayout.h>

@interface GSIndeterminateProgressView()
@property CGFloat CHUNK_WIDTH;
@property NSArray *colours;
@property NSUInteger colourIndex;
@property NSMutableArray *stripViews;
@property UIView *combinedProgressView;
@end

@implementation GSIndeterminateProgressView
@synthesize CHUNK_WIDTH;
@synthesize colourIndex;
@synthesize colours;
@synthesize stripViews;
@synthesize combinedProgressView;
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
        
        if (!combinedProgressView)
            combinedProgressView = [UIView new];
        combinedProgressView.frame = CGRectMake(0, 0, CHUNK_WIDTH, self.frame.size.height);
        UIView *strip = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CHUNK_WIDTH / 3, self.frame.size.height)];
        strip.autoresizesSubviews = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        strip.backgroundColor = self.progressTintColor;
        [combinedProgressView addSubview:strip];
        strip = [[UIView alloc] initWithFrame:CGRectMake(1 * (CHUNK_WIDTH / 3), 0, CHUNK_WIDTH / 3, self.frame.size.height)];
        strip.autoresizesSubviews = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        strip.backgroundColor = self.progressTintColor;
        [combinedProgressView addSubview:strip];
        strip = [[UIView alloc] initWithFrame:CGRectMake(2 * (CHUNK_WIDTH / 3), 0, CHUNK_WIDTH / 3, self.frame.size.height)];
        strip.autoresizesSubviews = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        strip.backgroundColor = self.progressTintColor;
        
        combinedProgressView.frame = CGRectMake(-CHUNK_WIDTH, 0, CHUNK_WIDTH, self.frame.size.height);
        [combinedProgressView addSubview:strip];

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
    
    self.progressChunks = @[combinedProgressView];

    for (UIView *v in self.progressChunks) {
        [self addSubview:v];
        [self animateProgressChunk:v delay:0];
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
    UIColor *tintColour = [colours objectAtIndex:colourIndex];
    colourIndex++;
    if (colourIndex >= colours.count)
        colourIndex = 0;
    return tintColour;
}

- (void)animateProgressChunk:(UIView *)chunk delay:(NSTimeInterval)delay
{
    [UIView animateWithDuration:1.6 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        chunk.hidden = NO;
        CGRect chuckFrame = chunk.frame;
        chuckFrame.origin.x = self.frame.size.width;
        chunk.frame = chuckFrame;
    } completion:^(BOOL finished) {
        CGRect chuckFrame = chunk.frame;
        chuckFrame.origin.x = -CHUNK_WIDTH;
        chunk.frame = chuckFrame;
        if (finished) {
            chunk.hidden = YES;
            [self animateProgressChunk:chunk delay:0.2];
        }
    }];
}

- (instancetype)initWithParentView:(UIView *)parentView alignToTop:(UIView *)topView {
    self = [[GSIndeterminateProgressView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [parentView addSubview:self];
    [self autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self autoPinEdge:ALEdgeTop
                        toEdge:ALEdgeTop
                        ofView:topView];
    [self autoSetDimension:ALDimensionHeight
                             toSize:2];
    [self layoutIfNeeded];

    return self;
}

@end
