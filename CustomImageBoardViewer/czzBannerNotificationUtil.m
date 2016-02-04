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

static NSTimeInterval defaultDisplayTime = 2.0;
static NSTimeInterval displayTimeWithCompletionHandler = 6.0;
static NSTimeInterval defaultAnimationDuration = 0.2;

@interface czzBannerNotificationUtil() <czzBannerViewDelegate>

@property (nonatomic, strong) czzBannerView *bannerView;
@property (nonatomic, strong) NSTimer *dismissTimer;
@property (nonatomic, assign) BannerNotificationPosition position;
@property (nonatomic, copy) void(^userInteractionHandler)(void);
@property (nonatomic, assign) BOOL waitForInteraction;
@property (nonatomic, readonly) CGRect topReferenceFrame;
@property (nonatomic, readonly) CGRect bottomReferenceFrame;
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
    DLog(@"message: %@", message);
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

    CGRect referenceFrame;
    if (self.position == BannerNotificationPositionTop) {
        referenceFrame = self.topReferenceFrame;
    } else {
        referenceFrame = self.bottomReferenceFrame;
    }
    if (self.bannerView.superview) {
        [self.bannerView removeFromSuperview];
    }
    if (self.position == BannerNotificationPositionTop) {
        // Position is top, move the banner down.
        referenceFrame.origin.y += self.bannerView.intrinsicContentSize.height;
    } else {
        // Position is bottom, move the banner up.
        referenceFrame.origin.y -= self.bannerView.intrinsicContentSize.height;
    }
    referenceFrame.size.height = self.bannerView.intrinsicContentSize.height;
    self.bannerView.frame = referenceFrame;
    [self.destinationViewController.view addSubview:self.bannerView];
    // If self.userInteractionHandler != nil, allowCancel.
    self.bannerView.allowCancel = self.userInteractionHandler != nil;
    
    // Start counting the timer.
    [self startTimer];
}

// Wrapper for dismissBannerView:(BOOL), always pass YES.
- (void)dismissBannerView {
    [self dismissBannerView:YES];
}

- (void)dismissBannerView:(BOOL)animated {
    if (self.bannerView.superview) {
        if (animated) {
            // Slide out of sign.
            CGRect targetFrame;
            if (self.position == BannerNotificationPositionTop) {
                targetFrame = self.topReferenceFrame;
            } else {
                targetFrame = self.bottomReferenceFrame;
            }
            DLog(@"Original frame: %@ -> target frame: %@", [NSValue valueWithCGRect:self.bannerView.frame], [NSValue valueWithCGRect:targetFrame]);
            [UIView animateWithDuration:defaultAnimationDuration animations:^{
                self.bannerView.frame = targetFrame;
            } completion:^(BOOL finished) {
                [self.bannerView removeFromSuperview];
            }];
        } else {
            [self.bannerView removeFromSuperview];
        }
    } else {
        DLog(@"Banner has no superview, its not displaying.");
    }
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
    DLog(@"");
    // Dismiss, then invoke the userInteractionHandler.
    [self dismissBannerView:YES];
    if (self.userInteractionHandler) {
        self.userInteractionHandler();
    }
}

- (void)bannerView:(czzBannerView *)bannerView didTouchButton:(UIButton *)button {
    DLog(@"");
    [self dismissBannerView:YES];
}

#pragma mark - Getters

- (czzBannerView *)bannerView {
    if (!_bannerView) {
        _bannerView = [czzBannerView viewFromNib];
        _bannerView.delegate = self;
    }
    return _bannerView;
}

- (CGRect)topReferenceFrame {
    UIViewController *referenceViewController = self.destinationViewController ?: [UIApplication topViewController];
    CGRect referenceFrame;
    if (!referenceViewController.navigationController.navigationBarHidden) {
        referenceFrame = referenceViewController.navigationController.navigationBar.frame;
    } else {
        // If hidden, show at the top most position instead.
        referenceFrame = CGRectMake(0, 0, CGRectGetWidth(referenceViewController.view.frame), 0);
    }
    return referenceFrame;
}

- (CGRect)bottomReferenceFrame {
    UIViewController *referenceViewController = self.destinationViewController ?: [UIApplication topViewController];
    CGRect referenceFrame;
    if (!referenceViewController.navigationController.toolbarHidden) {
        referenceFrame = referenceViewController.navigationController.toolbar.frame;
    } else {
        // No tool bar, show at the bottom of the screen.
        referenceFrame = CGRectMake(0, CGRectGetHeight(referenceViewController.view.frame), CGRectGetWidth(referenceViewController.view.frame), 0);
    }
    return referenceFrame;
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
