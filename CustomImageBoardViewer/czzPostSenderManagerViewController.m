//
//  czzPostSenderManagerViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 22/02/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzPostSenderManagerViewController.h"
#import "UIImage+animatedGIF.h"
#import "czzPostSenderManager.h"
#import "czzPostSender.h"
#import "czzPostViewController.h"
#import "czzBannerNotificationUtil.h"

@interface czzPostSenderManagerViewController ()<czzPostSenderManagerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *indicatorImageView;
@property (strong, nonatomic) czzPostViewController *lastPostViewController;
@end

@implementation czzPostSenderManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [PostSenderManager addDelegate:self];
    [self stopAnimatingWithCompletionHandler:nil]; // On viewDidLoad, clear everything.
}

- (void)startAnimating {
    NSURL *gifURL = [[NSBundle mainBundle] URLForResource:@"running_reed"
                                            withExtension:@"gif"];
    self.indicatorImageView.image = [UIImage animatedImageWithAnimatedGIFURL:gifURL];
    self.view.superview.userInteractionEnabled = YES;
}

- (void)stopAnimatingWithCompletionHandler:(void(^)(void))completionHandler {
    self.indicatorImageView.image = nil;
    // If a display only post view controller is currently presented, dismiss it.
    if (self.lastPostViewController) {
        [self.lastPostViewController dismissViewControllerAnimated:YES completion:completionHandler];
        self.lastPostViewController = nil;
    } else {
        // Not displaying last post view controller, perform completionHandler immediately.
        if (completionHandler) {
            completionHandler();
        }
    }
    // If currently not visible, set userInteractionEnabled to NO.
    self.view.superview.userInteractionEnabled = NO;
}

#pragma mark - UI actions.

- (IBAction)tapOnIndicatorView:(id)sender {
    DLog(@"");
    if (PostSenderManager.lastPostSender) {
        self.lastPostViewController = [czzPostViewController new];
        self.lastPostViewController.postMode = postViewControllerModeDisplayOnly;
        self.lastPostViewController.displayPostSender = PostSenderManager.lastPostSender;
        [[UIApplication rootViewController] presentViewController:[[UINavigationController alloc] initWithRootViewController:self.lastPostViewController]
                                                         animated:YES
                                                       completion:nil];
    }
}

#pragma mark - czzPostSenderManagerDelegate

- (void)postSenderManager:(czzPostSenderManager *)manager startPostingForSender:(czzPostSender *)postSender {
    [self startAnimating];
}

- (void)postSenderManager:(czzPostSenderManager *)manager postingCompletedForSender:(czzPostSender *)postSender success:(BOOL)success message:(NSString *)message {
    [self stopAnimatingWithCompletionHandler:^{
        if (success) {
            [czzBannerNotificationUtil displayMessage:@"提交成功"
                                             position:BannerNotificationPositionTop];
        } else {
            [czzBannerNotificationUtil displayMessage:message.length ? message : @"出错啦"
                                             position:BannerNotificationPositionTop];
        }
    }];
}

- (void)postSenderManager:(czzPostSenderManager *)manager postSender:(czzPostSender *)postSender progressUpdated:(CGFloat)percentage {
    // Display progress.
    if (PostSenderManager.lastPostSender == self.lastPostViewController.displayPostSender) {
        self.lastPostViewController.title = [NSString stringWithFormat:@"发送中 - %d%%", (int)(percentage * 100)];
    }
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"PostSenderManager"
                                     bundle:[NSBundle mainBundle]] instantiateInitialViewController];
}

@end
