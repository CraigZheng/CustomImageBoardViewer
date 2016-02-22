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

@interface czzPostSenderManagerViewController ()<czzPostSenderManagerDelegate>
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
    
    // If there's any remaining failed post sender, show warning.
    if (PostSenderManager.lastFailedPostSender) {
        [self showWarning];
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
    // If currently not visible, set userInteractionEnabled to NO.
}

- (void)showWarning {
    self.indicatorImageView.image = [UIImage imageNamed:@"38.png"];
    self.view.superview.userInteractionEnabled = YES;
}

#pragma mark - UI actions.

- (IBAction)tapOnIndicatorView:(id)sender {
    DLog(@"");
    if (PostSenderManager.lastFailedPostSender) {
        // TODO: Should retry?
        czzPostSender *failedPostSender = PostSenderManager.lastFailedPostSender;
        // Set the lastFailedPostSender in the manager to nil, indicate that the failed post sender has been consumed.
        [self stopAnimatingWithCompletionHandler:nil];
    } else if (PostSenderManager.lastPostSender) {
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
            // Keep a reference to the failed post sender, and display the warning icon.
            [self showWarning];
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
