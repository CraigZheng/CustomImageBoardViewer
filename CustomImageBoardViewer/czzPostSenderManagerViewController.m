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
#import "czzReplyUtil.h"
#import "czzBannerNotificationUtil.h"
#import "CustomImageBoardViewer-Swift.h"

@interface czzPostSenderManagerViewController ()<czzPostSenderManagerDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *indicatorImageView;
@property (strong, nonatomic) czzPostViewController *lastPostViewController;
@end

@implementation czzPostSenderManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CAShapeLayer *circle = [CAShapeLayer layer];
    // Make a circular shape
    UIBezierPath *circularPath=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.indicatorImageView.frame.size.width, self.indicatorImageView.frame.size.height) cornerRadius:MAX(self.indicatorImageView.frame.size.width, self.indicatorImageView.frame.size.height)];
    circle.path = circularPath.CGPath;
    // Configure the apperence of the circle
    // Make the indicator image view round.
    circle.fillColor = [UIColor blackColor].CGColor;
    circle.strokeColor = [UIColor blackColor].CGColor;
    circle.lineWidth = 0;
    self.indicatorImageView.layer.mask=circle;
    
    [PostSenderManager addDelegate:self];
    [self stopAnimatingWithCompletionHandler:nil]; // On viewDidLoad, clear everything.
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Adjust self according to the status of PostSenderManager.
    [self stopAnimatingWithCompletionHandler:nil];
    // If there's any active posting.
    if (PostSenderManager.lastPostSender) {
        [self startAnimating];
    }
    // If there's any remaining failed post sender, show warning.
    else if (PostSenderManager.lastFailedPostSender) {
        [self showError];
    }
}

- (void)startAnimating {
    NSURL *gifURL = [[NSBundle mainBundle] URLForResource:@"running_reed"
                                            withExtension:@"gif"];
    self.indicatorImageView.image = [UIImage animatedImageWithAnimatedGIFURL:gifURL];
    self.view.superview.userInteractionEnabled = YES;
}

- (void)stopAnimatingWithCompletionHandler:(void(^)(void))completionHandler {
    self.indicatorImageView.image = nil;
    // If currently not visible, set userInteractionEnabled to NO.
    self.view.superview.userInteractionEnabled = NO;
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
}

- (void)showError {
    self.indicatorImageView.image = [UIImage imageNamed:@"38.png"];
    self.view.superview.userInteractionEnabled = YES;
}

- (void)showWarning {
    self.indicatorImageView.image = [UIImage imageNamed:@"21.png"];
    self.view.superview.userInteractionEnabled = YES;
}

#pragma mark - UI actions.

- (IBAction)tapOnIndicatorView:(id)sender {
    DLog(@"");
    if (PostSenderManager.lastFailedPostSender) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"发送失败,是否重试?"
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"取消"
                                                  otherButtonTitles:@"重试", nil];
        [alertView show];
    } else if (PostSenderManager.severeWarnedPostSender) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"无法确认信息发送成功,可能是网络错误,没有饼干,图片太大,或者含有敏感词!"
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"取消"
                                                  otherButtonTitles:@"重试", nil];
        [alertView show];
    } else if (PostSenderManager.lastPostSender) {
        self.lastPostViewController = [czzPostViewController new];
        self.lastPostViewController.postMode = postViewControllerModeDisplayOnly;
        self.lastPostViewController.displayPostSender = PostSenderManager.lastPostSender;
        [[UIApplication rootViewController] presentViewController:[[UINavigationController alloc] initWithRootViewController:self.lastPostViewController]
                                                         animated:YES
                                                       completion:nil];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // There's only 1 alert view in this view controller: retry post alert view.
    czzPostSender *failedPostSender = PostSenderManager.lastFailedPostSender ?: PostSenderManager.severeWarnedPostSender;
    PostSenderManager.lastFailedPostSender = PostSenderManager.severeWarnedPostSender = nil; // The failed post sender has been consumed.
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"重试"] && failedPostSender) {
        // Retry the failed post sender.
        [self stopAnimatingWithCompletionHandler:^{
            czzPostViewController *retryPostViewController = [czzPostViewController new];
            retryPostViewController.postSender = failedPostSender;
            switch (failedPostSender.postMode) {
                case postSenderModeNew:
                    retryPostViewController.postMode = postViewControllerModeNew;
                    break;
                case postSenderModeReply:
                    retryPostViewController.postMode = postSenderModeReply;
                default:
                    break;
            }
            [[UIApplication rootViewController] presentViewController:[[UINavigationController alloc] initWithRootViewController:retryPostViewController]
                                                             animated:YES
                                                           completion:nil];
        }];
    } else {
        // Don't retry, just dismiss the error.
        [self stopAnimatingWithCompletionHandler:nil];
    }
}

#pragma mark - czzPostSenderManagerDelegate

- (void)postSenderManager:(czzPostSenderManager *)manager startPostingForSender:(czzPostSender *)postSender {
    [self startAnimating];
}

- (void)postSenderManager:(czzPostSenderManager *)manager severeWarningReceivedForPostSender:(czzPostSender *)postSender message:(NSString *)message {
    [self showWarning];
    [MessagePopup showMessagePopupWithTitle:@"无法确认信息发送成功"
                                    message:message
                                     layout:MessagePopupLayoutMessageView
                                      theme:MessagePopupThemeError
                                   position:MessagePopupPresentationStyleBottom
                                buttonTitle:@"OK"
                        buttonActionHandler:^(UIButton * _Nonnull button){
                            [MessagePopup hide];
                        }];
}

- (void)postSenderManager:(czzPostSenderManager *)manager postingCompletedForSender:(czzPostSender *)postSender success:(BOOL)success message:(NSString *)message {
    [self stopAnimatingWithCompletionHandler:^{
        // Delay just a bit.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (success) {
                [czzBannerNotificationUtil displayMessage:@"提交成功"
                                                 position:BannerNotificationPositionTop];
            } else {
                [czzBannerNotificationUtil displayMessage:message.length ? message : @"出错啦"
                                                 position:BannerNotificationPositionTop];
                // Keep a reference to the failed post sender, and display the warning icon.
                [self showError];
            }
        });
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
