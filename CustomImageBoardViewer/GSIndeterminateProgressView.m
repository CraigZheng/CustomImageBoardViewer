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
@property UIView *foregroundBarView;
@property UIView *backgroundBarView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign) BOOL isAnimating;
@end

@implementation GSIndeterminateProgressView
@synthesize CHUNK_WIDTH;
@synthesize colourIndex;
@synthesize colours;

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
        colours = @[[UIColor cyanColor], [UIColor yellowColor], [UIColor magentaColor], [UIColor whiteColor]];//, [UIColor blackColor]];
        
        // Make self transparent, so the colourful progress bars are more obvious.
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)didMoveToWindow {
    if (self.window && self.isAnimating) {
        DLog(@"Did move to window and should be animating, resuming animation...");
        [self stopAnimating];
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
    DLog(@"");
    self.hidden = NO;
    self.isAnimating = YES;
    [self resetViews];
    if (!self.containerView) {
        self.containerView = [UIView new];
        [self addSubview:self.containerView];
        [self.containerView autoPinEdgesToSuperviewEdges];
    }
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
    NSInteger count = CHUNK_WIDTH / warningChunkWidth;
    if (!self.containerView) {
        self.containerView = [UIView new];
        [self addSubview:self.containerView];
        [self.containerView autoPinEdgesToSuperviewEdges];
    }
    for (NSInteger i = 0; i <= count; i++) {
        UIView *stripView = [[UIView alloc] initWithFrame:CGRectMake(i * 2 * warningChunkWidth, 0, warningChunkWidth, self.frame.size.height)];
        stripView.backgroundColor = [UIColor colorWithRed:220/255. green:20/255. blue:60/255. alpha:1.0]; //220	20	60
        [self.containerView addSubview:stripView];
    }
    self.backgroundColor = [UIColor whiteColor];
    [self setNeedsDisplay];
}

- (void)resetViews {
    [self.containerView removeFromSuperview];
    self.containerView = nil;
    [self setNeedsDisplay];
}

#pragma mark - Getters

-(UIColor*)progressTintColor {
    UIColor *tintColour = [colours objectAtIndex:colourIndex];
    colourIndex++;
    if (colourIndex >= colours.count)
        colourIndex = 0;
    return tintColour;
}

- (void)animateProgressChunkWithDelay:(NSTimeInterval)delay {
    // Add foreground views to self.
    self.foregroundBarView = [[UIView alloc] init];
    [self.containerView addSubview:self.foregroundBarView];
    // Assign a new colour for foreground views.
    self.foregroundBarView.backgroundColor = self.progressTintColor;
    // Assign new positions.
    // Left and Right: starting from middle.
    NSArray *constraints = [self.foregroundBarView autoSetDimensionsToSize:CGSizeMake(0, 2)];
    [self.foregroundBarView autoCenterInSuperview];
    [self layoutIfNeeded];
    
    __weak typeof(self) weakSelf= self;
    UIView *containerView = weakSelf.containerView;
    [UIView animateWithDuration:0.8 animations:^{
        for (NSLayoutConstraint *constraint in constraints) {
            [constraint autoRemove];
        }
        [weakSelf.foregroundBarView autoSetDimensionsToSize:CGSizeMake(CGRectGetWidth(self.frame), 2)];
        [weakSelf layoutIfNeeded];
    } completion:^(BOOL finished) {
        // If the containerView is no longer the same one, means the [self resetViews] has been called, in such case, no action should be taken.
        if (containerView == weakSelf.containerView) {
            // If previous background views are still here, remove them.
            if (weakSelf.backgroundBarView.superview) {
                [weakSelf.backgroundBarView removeFromSuperview];
            }
            if (weakSelf.isAnimating && weakSelf.window) {
                // On finish, keep references to the foreground views.
                weakSelf.backgroundBarView = weakSelf.foregroundBarView;
                [weakSelf animateProgressChunkWithDelay:delay];
            }
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
