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
@property (nonatomic, strong) UIView *foregroundBarView;
@property (nonatomic, strong) NSLayoutConstraint *foregroundBarWidthConstraint;
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
        return;
    }
    self.hidden = self.foregroundBarView.hidden = NO;
    self.isAnimating = YES;
    [self resetViews];
    [self animateProgressChunkWithDelay:0.2];
    [self setNeedsDisplay];
}

- (void)stopAnimating
{
    self.isAnimating = NO;
    self.hidden = self.foregroundBarView.hidden = YES;
    [self resetViews];
    [self setNeedsDisplay];
}

-(void)showWarning {
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
        return;
    }
    if (!self.foregroundBarView) {
        self.foregroundBarView = [UIView new];
        self.foregroundBarView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.foregroundBarView];
        self.foregroundBarWidthConstraint = [self.foregroundBarView.widthAnchor constraintEqualToConstant:0];
        [NSLayoutConstraint activateConstraints:@[
            [self.foregroundBarView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [self.foregroundBarView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [self.foregroundBarView.heightAnchor constraintEqualToConstant:2],
            self.foregroundBarWidthConstraint
        ]];
    }
    // Remove all previous traces.
    [self.foregroundBarView.layer removeAllAnimations];
    // Assign a new colour for foreground views.
    self.foregroundBarView.backgroundColor = self.progressTintColor;
    // Assign new positions.
    // Left and Right: starting from middle.
    self.foregroundBarWidthConstraint.constant = 0;
    [self layoutIfNeeded];
    
    __weak typeof(self) weakSelf= self;
    [UIView animateWithDuration:0.8
                          delay:delay
                        options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         weakSelf.foregroundBarWidthConstraint.constant = CGRectGetWidth(self.frame);
                         [weakSelf layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         // On finished, set colour of self, and remove the foregroundBarView.
                         self.backgroundColor = self.foregroundBarView.backgroundColor;
                         if (weakSelf.isAnimating && self.window && finished) {
                             [weakSelf animateProgressChunkWithDelay:delay];
                         }
                     }];
}

- (instancetype)initWithParentView:(UIView *)parentView alignToTop:(UIView *)topView {
    self = [[GSIndeterminateProgressView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [parentView addSubview:self];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.leadingAnchor constraintEqualToAnchor:parentView.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:parentView.trailingAnchor],
        [self.topAnchor constraintEqualToAnchor:topView.topAnchor],
        [self.heightAnchor constraintEqualToConstant:2]
    ]];
    [self layoutIfNeeded];

    return self;
}

@end
