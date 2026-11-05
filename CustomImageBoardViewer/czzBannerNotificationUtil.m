//
//  czzBannerNotification.m
//  CustomImageBoardViewer
//
//  Created by Craig on 3/02/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzBannerNotificationUtil.h"

#import "czzBannerView.h"
#import "UIApplication+Util.h"

#import <QuartzCore/QuartzCore.h>

static NSTimeInterval defaultDisplayTime = 3.0;
static NSTimeInterval displayTimeWithCompletionHandler = 6.0;
static NSTimeInterval defaultAnimationDuration = 0.2;

@interface czzBannerNotificationUtil() <czzBannerViewDelegate>

@property (nonatomic, strong) czzBannerView *bannerView;
@property (nonatomic, strong) NSTimer *dismissTimer;
@property (nonatomic, assign) BannerNotificationPosition position;
@property (nonatomic, copy) void(^userInteractionHandler)(void);
@property (nonatomic, assign) BOOL waitForInteraction;
@property (nonatomic, strong) NSLayoutConstraint *bannerEdgeConstraint;
@property (nonatomic, weak) UIViewController *destinationViewController;

@end

@implementation czzBannerNotificationUtil

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleUIApplicationWillChangeStatusBarFrameNotification)
                                                     name:UIApplicationWillChangeStatusBarFrameNotification
                                                   object:nil];
    }
    return self;
}

- (void)displayMessage:(NSString *)message position:(BannerNotificationPosition)position userInteractionHandler:(void (^)(void))userInteractionHandler waitForInteraction:(BOOL)waitForInteraction{
    self.position = position;
    self.userInteractionHandler = userInteractionHandler;
    self.bannerView.title = message;
    self.waitForInteraction = waitForInteraction;
    [self displayBannerView];
}

- (void)displayBannerView {
    // When the banner is being displayed, keep a reference to the banner notification.
    self.destinationViewController = [UIApplication topViewController];
    if (!self.destinationViewController) {
        return;
    }

    [self.bannerView.layer removeAllAnimations];
    if (self.bannerView.superview) {
        [self.bannerView removeFromSuperview];
    }
    // If self.userInteractionHandler != nil, allowCancel.
    self.bannerView.allowCancel = self.userInteractionHandler != nil;

    UIView *hostView = self.destinationViewController.view;
    self.bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    [hostView addSubview:self.bannerView];

    // The banner hugs the safe area on the requested edge. Both edges use the same
    // constraint so the slide can be animated by changing its constant.
    UILayoutGuide *safeArea = hostView.safeAreaLayoutGuide;
    BOOL isTop = self.position == BannerNotificationPositionTop;
    NSLayoutConstraint *edgeConstraint = isTop
        ? [self.bannerView.topAnchor constraintEqualToAnchor:safeArea.topAnchor]
        : [self.bannerView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor];
    self.bannerEdgeConstraint = edgeConstraint;
    [NSLayoutConstraint activateConstraints:@[
        [self.bannerView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [self.bannerView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
        edgeConstraint
    ]];

    // Lay out first so the banner has its intrinsic height, then start it just
    // off the requested edge. The constant applies to the anchored edge, so a top
    // banner starts negative (above the safe area) and a bottom one positive.
    [hostView layoutIfNeeded];
    CGFloat offScreenOffset = CGRectGetHeight(self.bannerView.bounds);
    if (isTop) {
        offScreenOffset = -offScreenOffset;
    }
    edgeConstraint.constant = offScreenOffset;
    [hostView layoutIfNeeded];

    // Force the off screen position into the render tree, otherwise Core Animation
    // captures the wrong starting point for the slide.
    [CATransaction flush];

    edgeConstraint.constant = 0;
    [hostView setNeedsLayout];
    [UIView animateWithDuration:defaultAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [hostView layoutIfNeeded];
                     }
                     completion:nil];

    // Start counting the timer.
    [self startTimer];
}

// Wrapper for dismissBannerView:(BOOL), always pass YES.
- (void)dismissBannerView {
    [self dismissBannerView:YES];
}

- (void)dismissBannerView:(BOOL)animated {
    if (!self.bannerView.superview) {
        DLog(@"Banner has no superview, its not displaying.");
        return;
    }
    if (!animated || !self.bannerEdgeConstraint) {
        [self.bannerView removeFromSuperview];
        return;
    }
    // Slide back out past the same edge, then remove.
    UIView *hostView = self.bannerView.superview;
    CGFloat offScreenOffset = CGRectGetHeight(self.bannerView.bounds);
    if (self.position == BannerNotificationPositionTop) {
        offScreenOffset = -offScreenOffset;
    }
    self.bannerEdgeConstraint.constant = offScreenOffset;
    [UIView animateWithDuration:defaultAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [hostView layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         [self.bannerView removeFromSuperview];
                     }];
}

#pragma mark - NSTimer management
- (void)startTimer {
    [self stopTimer];
    NSTimeInterval displayTime = defaultDisplayTime;
    // If the caller provides a handler, make the display time a bit longer.
    if (self.userInteractionHandler) {
        displayTime = displayTimeWithCompletionHandler;
        // If the caller provides a handler, and wants to wait for interaction.
        if (self.waitForInteraction) {
            displayTime = MAXFLOAT;
        }
    }
    self.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:displayTime
                                                         target:self
                                                       selector:@selector(dismissBannerView)
                                                       userInfo:nil
                                                        repeats:NO];
}

- (void)stopTimer {
    if (self.dismissTimer.isValid) {
        [self.dismissTimer invalidate];
    }
}

#pragma mark - Rotation event
- (void)handleUIApplicationWillChangeStatusBarFrameNotification {
    // If the banner is still showing, dismiss it first, then display it again after the animation.
    if (self.bannerView.superview) {
        [self dismissBannerView:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((defaultAnimationDuration * 2) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self displayBannerView];
        });
    }
}

#pragma mark - czzBannerViewDelegate

- (void)bannerViewDidTouch:(czzBannerView *)bannerView {
    // Dismiss, then invoke the userInteractionHandler.
    [self dismissBannerView:YES];
    if (self.userInteractionHandler) {
        self.userInteractionHandler();
    }
}

- (void)bannerView:(czzBannerView *)bannerView didTouchButton:(UIButton *)button {
    [self dismissBannerView:YES];
}

#pragma mark - Getters

- (czzBannerView *)bannerView {
    if (!_bannerView) {
        _bannerView = [[czzBannerView alloc] init];
        _bannerView.delegate = self;
    }
    return _bannerView;
}

- (UIViewController *)destinationViewController {
    UIViewController *targetViewController = _destinationViewController;
    if ([_destinationViewController isKindOfClass:[UINavigationController class]]) {
        targetViewController = (UINavigationController *)_destinationViewController.childViewControllers.lastObject;
    }
    return targetViewController;
}

+ (void)displayMessage:(NSString *)message position:(BannerNotificationPosition)position {
    [self displayMessage:message
                position:position
  userInteractionHandler:nil
      waitForInteraction:NO];
}

+ (void)displayMessage:(NSString *)message position:(BannerNotificationPosition)position userInteractionHandler:(void (^)(void))userInteractionHandler waitForInteraction:(BOOL)waitForInteraction{
    [[self sharedInstance] displayMessage:message
                                 position:position
                   userInteractionHandler:userInteractionHandler
                       waitForInteraction:waitForInteraction];
}

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [czzBannerNotificationUtil new];
    });
    return sharedInstance;
}

@end
