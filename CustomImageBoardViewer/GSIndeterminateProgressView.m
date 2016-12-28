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
@property (nonatomic, strong) UIView *foregroundBarView;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, strong) NSMutableArray *stripViews;
@property (nonatomic, assign) BOOL isReady;
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
        self.colours = @[[UIColor magentaColor], [UIColor cyanColor], [UIColor yellowColor], [UIColor greenColor]];//, [UIColor blackColor]];
        self.stripViews = [NSMutableArray new];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          // No longer ready.
                                                          self.isReady = NO;
                                                          if (self.isAnimating) {
                                                              [self resetViews];
                                                          }
                                                      }];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          self.isReady = YES;
                                                          if (self.window && self.isAnimating) {
//                                                              DLog(@"View did becom active, resuming animation.");
                                                              [self animateProgressChunkWithDelay:0];
                                                          }
                                                      }];
    }
    return self;
}

- (void)dealloc {
    // Remove notification observers.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidDisapper {
    self.isReady = NO;
    [self resetViews];
}

- (void)viewDidAppear {
    self.isReady = YES;
    if (self.window && self.isAnimating) {
//        DLog(@"View did appear - resuming animation.");
        [self animateProgressChunkWithDelay:0];
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
    if (self.isAnimating) {
//        DLog(@"Already animating");
        return;
    }
//    DLog(@"");
    self.hidden = self.foregroundBarView.hidden = NO;
    self.isAnimating = YES;
    [self resetViews];
    [self animateProgressChunkWithDelay:0.2];
    [self setNeedsDisplay];
}

- (void)stopAnimating
{
//    DLog(@"");
    self.isAnimating = NO;
    self.hidden = self.foregroundBarView.hidden = YES;
    [self resetViews];
    [self setNeedsDisplay];
}

-(void)showWarning {
//    DLog(@"");
    [self stopAnimating];
    
    static CGFloat warningChunkWidth = 20.;
    NSInteger count = self.CHUNK_WIDTH / warningChunkWidth;
    for (NSInteger i = 0; i <= count; i++) {
        UIView *stripView = [[UIView alloc] initWithFrame:CGRectMake(i * 2 * warningChunkWidth, 0, warningChunkWidth, self.frame.size.height)];
        stripView.backgroundColor = [UIColor colorWithRed:220/255. green:20/255. blue:60/255. alpha:1.0]; //220	20	60
        [self addSubview:stripView];
        [self.stripViews addObject:stripView];
    }
    self.backgroundColor = [UIColor whiteColor];
    self.hidden = NO;
    self.foregroundBarView.hidden = YES;
    self.foregroundBarView.backgroundColor = [UIColor whiteColor];
}

- (void)resetViews {
    [self.foregroundBarView.layer removeAllAnimations];
    self.backgroundColor = [UIColor whiteColor];
    for (UIView *stripView in self.stripViews) {
        [stripView removeFromSuperview];
    }
    [self.stripViews removeAllObjects];
    [self setNeedsDisplay];
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
    if (!self.isReady) {
//        DLog(@"Progress view is not ready.");
        return;
    }
    if (!self.foregroundBarView) {
        self.foregroundBarView = [UIView newAutoLayoutView];
        [self addSubview:self.foregroundBarView];
    }
    // Remove all previous traces.
    [self.foregroundBarView.layer removeAllAnimations];
    [self.foregroundBarView.constraints autoRemoveConstraints];
    // Assign a new colour for foreground views.
    self.foregroundBarView.backgroundColor = self.progressTintColor;
    // Assign new positions.
    // Left and Right: starting from middle.
    [self.foregroundBarView autoCenterInSuperview];
    [self.foregroundBarView autoSetDimensionsToSize:CGSizeMake(0, 2)];
    [self layoutIfNeeded];
    
    __weak typeof(self) weakSelf= self;
    [UIView animateWithDuration:0.8
                          delay:delay
                        options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         // Remove all constraints and assign new ones.
                         [weakSelf.foregroundBarView.constraints autoRemoveConstraints];
                         [weakSelf.foregroundBarView autoSetDimensionsToSize:CGSizeMake(CGRectGetWidth(self.frame), 2)];
                         [weakSelf layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         // On finished, set colour of self, and remove the foregroundBarView.
                         self.backgroundColor = self.foregroundBarView.backgroundColor;
                         if (weakSelf.isAnimating && self.window && finished) {
                             [weakSelf animateProgressChunkWithDelay:delay];
                         } else {
//                             DLog(@"Animation not going to repeat.");
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
