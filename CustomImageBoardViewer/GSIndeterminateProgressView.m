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
@property (nonatomic, weak) UIView *foregroundBarView;
@property (nonatomic, assign) BOOL isAnimating;
@end

@implementation GSIndeterminateProgressView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        
        self.trackTintColor = [UIColor clearColor];
        self.progressTintColor = [UIColor blueColor];
        
        self.hidesWhenStopped = YES;
        self.hidden = YES;
        
        self.CHUNK_WIDTH = MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        self.colourIndex = 0;
        self.colours = @[[UIColor cyanColor], [UIColor yellowColor], [UIColor magentaColor], [UIColor whiteColor]];//, [UIColor blackColor]];
        
        // Make self transparent, so the colourful progress bars are more obvious.
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)didMoveToWindow {
    if (self.window) {
        if (self.isAnimating) {
            [self startAnimating];
        }
    } else {
        [self resetViews];
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
    DLog(@"");
    self.hidden = NO;
    self.isAnimating = YES;
    [self resetViews];
    [self animateProgressChunkWithDelay:0.2];
    [self setNeedsDisplay];
}

- (void)stopAnimating
{
    DLog(@"");
    self.isAnimating = NO;
    self.hidden = YES;
    [self resetViews];
    [self setNeedsDisplay];
}

-(void)showWarning {
    DLog(@"");
    [self stopAnimating];
    self.hidden = NO;
    
    static CGFloat warningChunkWidth = 20.;
    NSInteger count = self.CHUNK_WIDTH / warningChunkWidth;
    for (NSInteger i = 0; i <= count; i++) {
        UIView *stripView = [[UIView alloc] initWithFrame:CGRectMake(i * 2 * warningChunkWidth, 0, warningChunkWidth, self.frame.size.height)];
        stripView.backgroundColor = [UIColor colorWithRed:220/255. green:20/255. blue:60/255. alpha:1.0]; //220	20	60
        [self addSubview:stripView];
    }
    self.backgroundColor = [UIColor whiteColor];
}

- (void)resetViews {
    [self.foregroundBarView.layer removeAllAnimations];
    [self.layer removeAllAnimations];
    for (UIView *subView in self.subviews) {
        [subView removeFromSuperview];
    }
}

#pragma mark - Getters

-(UIColor*)progressTintColor {
    UIColor *tintColour = [self.colours objectAtIndex:self.colourIndex];
    self.colourIndex++;
    if (self.colourIndex >= self.colours.count)
        self.colourIndex = 0;
    return tintColour;
}

- (void)animateProgressChunkWithDelay:(NSTimeInterval)delay {
    // Add foreground views to self.
    UIView *view = [[UIView alloc] init];
    [self addSubview:view];
    self.foregroundBarView = view;
    // Assign a new colour for foreground views.
    self.foregroundBarView.backgroundColor = self.progressTintColor;
    // Assign new positions.
    // Left and Right: starting from middle.
    NSArray *constraints = [self.foregroundBarView autoSetDimensionsToSize:CGSizeMake(0, 2)];
    [self.foregroundBarView autoCenterInSuperview];
    [self layoutIfNeeded];
    
    __weak typeof(self) weakSelf= self;
    [UIView animateWithDuration:0.8
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        for (NSLayoutConstraint *constraint in constraints) {
            [constraint autoRemove];
        }
        [weakSelf.foregroundBarView autoSetDimensionsToSize:CGSizeMake(CGRectGetWidth(self.frame), 2)];
        [weakSelf layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (!finished) {
            DLog(@"Animation not finished!");
        }
        // On finished, set colour of self, and remove the foregroundBarView.
        self.backgroundColor = self.foregroundBarView.backgroundColor;
        [self.foregroundBarView removeFromSuperview];
        if (weakSelf.isAnimating && self.window) {
            [weakSelf animateProgressChunkWithDelay:delay];
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
