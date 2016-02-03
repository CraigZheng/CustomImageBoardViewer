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

@interface czzBannerNotificationUtil() <czzBannerViewDelegate>

@property (nonatomic, strong) czzBannerView *bannerView;

@end

@implementation czzBannerNotificationUtil

- (void)displayMessage:(NSString *)message position:(BannerNotificationPosition)position completionHandler:(void (^)(void))completionHandler {
    DLog(@"message: %@", message);
    UIViewController *topViewController = [UIApplication topViewController];
    self.bannerView.title = message;
    if (!topViewController.navigationController.toolbarHidden) {
        if (self.bannerView.superview) {
            [self.bannerView removeFromSuperview];
        }
        [topViewController.view addSubview:self.bannerView];
        CGRect targetFrame = topViewController.navigationController.toolbar.frame;
        targetFrame.origin.y -= self.bannerView.intrinsicContentSize.height;
        targetFrame.size.height = self.bannerView.intrinsicContentSize.height;
        self.bannerView.frame = targetFrame;
    } else {
        
    }
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

+ (void)displayMessage:(NSString *)message position:(BannerNotificationPosition)position userInteractionHandler:(void (^)(void))completionHandler {
    [[self sharedInstance] displayMessage:message
                                 position:position
                        completionHandler:completionHandler];
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
