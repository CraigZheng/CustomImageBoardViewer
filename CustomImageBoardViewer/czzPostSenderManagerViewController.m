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

@interface czzPostSenderManagerViewController ()<czzPostSenderManagerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *indicatorImageView;
@property (strong, nonatomic) czzPostViewController *lastPostViewController;
@end

@implementation czzPostSenderManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [PostSenderManager addDelegate:self];
}

- (void)startAnimating {
    NSURL *gifURL = [[NSBundle mainBundle] URLForResource:@"running_reed"
                                            withExtension:@"gif"];
    self.indicatorImageView.image = [UIImage animatedImageWithAnimatedGIFURL:gifURL];
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
    self.indicatorImageView.image = nil;
    if (self.lastPostViewController) {
        [self.lastPostViewController dismissViewControllerAnimated:YES completion:nil];
        self.lastPostViewController = nil;
    }
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"PostSenderManager"
                                     bundle:[NSBundle mainBundle]] instantiateInitialViewController];
}

@end
