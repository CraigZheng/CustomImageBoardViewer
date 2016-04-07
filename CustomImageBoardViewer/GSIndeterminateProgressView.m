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
@property UIView *leftForegroundView;
@property UIView *rightForegroundView;
@property UIView *leftBackgroundView;
@property UIView *rightBackgroundView;
@end

@implementation GSIndeterminateProgressView
@synthesize CHUNK_WIDTH;
@synthesize colourIndex;
@synthesize colours;
@synthesize stripViews;
@synthesize isAnimating = _isAnimating;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        
        self.trackTintColor = [UIColor clearColor];
        self.progressTintColor = [UIColor blueColor];
        
        self.hidesWhenStopped = YES;
        self.hidden = YES;
        
        CHUNK_WIDTH = MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        colourIndex = 0;
        colours = @[[UIColor cyanColor], [UIColor magentaColor], [UIColor yellowColor], [UIColor clearColor]];//, [UIColor blackColor]];
        
        // Make self transparent, so the colourful progress bars are more obvious.
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)didMoveToWindow {
    if (self.window && self.isAnimating) {
        DLog(@"Did move to window and should be animating, resuming animation...");
        _isAnimating = NO;
        [self startAnimating];
    }
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
    for (UIView *stripView in stripViews) {
        [stripView removeFromSuperview];
    }
    [stripViews removeAllObjects];
    
    [self animateProgressChunkWithDelay:0.2];
}

- (void)stopAnimating
{
    if (!_isAnimating) return;
    _isAnimating = NO;

    self.hidden = self.hidesWhenStopped;

    for (UIView *stripView in stripViews) {
        [stripView removeFromSuperview];
    }
    [self.leftForegroundView removeFromSuperview];
    [self.rightForegroundView removeFromSuperview];
    [self.leftBackgroundView removeFromSuperview];
    [self.rightBackgroundView removeFromSuperview];
    [stripViews removeAllObjects];
}

-(void)showWarning {
    [self stopAnimating];
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

- (void)animateProgressChunkWithDelay:(NSTimeInterval)delay {
    DLog(@"");
    // Add foreground views to self.
    self.rightForegroundView = [[UIView alloc] init];
    self.leftForegroundView = [[UIView alloc] init];
    [self addSubview:self.leftForegroundView];
    [self addSubview:self.rightForegroundView];
    // Assign a new colour for foreground views.
    self.leftForegroundView.backgroundColor = self.rightForegroundView.backgroundColor = self.progressTintColor;
    // Assign new positions.
    // Left and Right: starting from middle.
    self.rightForegroundView.frame = self.leftForegroundView.frame = CGRectMake(CGRectGetWidth(self.frame) / 2, 0, 0, CGRectGetHeight(self.frame));
    DLog(@"Left view frame: %@", [NSValue valueWithCGRect:self.leftForegroundView.frame]);
    
    [UIView animateWithDuration:0.8 animations:^{
        // Left: move to the left, and expanding.
        self.leftForegroundView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame) / 2, CGRectGetHeight(self.frame));
        // Right: expanding.
        CGRect rightFrame = self.rightForegroundView.frame;
        rightFrame.size.width = CGRectGetWidth(self.frame) / 2;
        self.rightForegroundView.frame = rightFrame;
        DLog(@"Left view frame: %@", [NSValue valueWithCGRect:self.leftForegroundView.frame]);
    } completion:^(BOOL finished) {
        if (finished && _isAnimating) {
            // If previous background views are still here, remove them.
            if (self.leftBackgroundView.superview) {
                [self.leftBackgroundView removeFromSuperview];
            }
            if (self.rightBackgroundView.superview) {
                [self.rightBackgroundView removeFromSuperview];
            }
            // On finish, keep references to the foreground views.
            self.leftBackgroundView = self.leftForegroundView;
            self.rightBackgroundView = self.rightBackgroundView;
            [self animateProgressChunkWithDelay:delay];
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
