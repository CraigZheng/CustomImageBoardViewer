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

@interface czzBannerNotificationUtil() <czzBannerViewDelegate>

@property (nonatomic, strong) czzBannerView *bannerView;
@property (nonatomic, strong) NSTimer *dismissTimer;
@property (nonatomic, assign) BannerNotificationPosition position;
@property (nonatomic, copy) void(^userInteractionHandler)(void);

@end

@implementation czzBannerNotificationUtil

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleUIApplicationDidChangeStatusBarOrientation)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    return self;
}

- (void)displayMessage:(NSString *)message position:(BannerNotificationPosition)position userInteractionHandler:(void (^)(void))userInteractionHandler {
    DLog(@"message: %@", message);
    self.position = position;
    self.userInteractionHandler = userInteractionHandler;
    self.bannerView.title = message;
    [self displayBannerView];
}

- (void)displayBannerView {
    UIViewController *topViewController = [UIApplication topViewController];
    if (!topViewController) {
        return;
    }

    CGRect referenceFrame;
    if (self.position == BannerNotificationPositionTop) {
        if (!topViewController.navigationController.navigationBarHidden) {
            referenceFrame = topViewController.navigationController.navigationBar.frame;
        } else {
            // If hidden, show at the top most position instead.
            referenceFrame = CGRectMake(0, 0, CGRectGetWidth(topViewController.view.frame), 0);
        }
    } else {
        referenceFrame = topViewController.navigationController.toolbar.frame;
        if (!topViewController.navigationController.toolbarHidden) {
            referenceFrame = topViewController.navigationController.toolbar.frame;
        } else {
            // No tool bar, show at the bottom of the screen.
            referenceFrame = CGRectMake(0, CGRectGetHeight(topViewController.view.frame), CGRectGetWidth(topViewController.view.frame), 0);
        }
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
    [topViewController.view addSubview:self.bannerView];
}

#pragma mark - Rotation event
- (void)handleUIApplicationDidChangeStatusBarOrientation {
    // TODO: dismiss first.
    // TODO: pass the position.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self displayBannerView];
    });
}

#pragma mark - czzBannerViewDelegate

- (void)bannerViewDidTouch:(czzBannerView *)bannerView {
    DLog(@"");
}

- (void)bannerView:(czzBannerView *)bannerView didTouchButton:(UIButton *)button {
    DLog(@"");
}

#pragma mark - Getters

- (czzBannerView *)bannerView {
    if (!_bannerView) {
        _bannerView = [czzBannerView viewFromNib];
        _bannerView.delegate = self;
    }
    return _bannerView;
}

+ (void)displayMessage:(NSString *)message position:(BannerNotificationPosition)position {
    [self displayMessage:message
                position:position
       userInteractionHandler:nil];
}

+ (void)displayMessage:(NSString *)message position:(BannerNotificationPosition)position userInteractionHandler:(void (^)(void))userInteractionHandler {
    [[self sharedInstance] displayMessage:message
                                 position:position
                        userInteractionHandler:userInteractionHandler];
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
