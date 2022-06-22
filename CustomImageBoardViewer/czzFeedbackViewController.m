//
//  czzFeedbackViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 29/05/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzFeedbackViewController.h"
#import "FPPopoverController.h"
#import "czzAppDelegate.h"
#import "czzSettingsCentre.h"
#import "Toast+UIView.h"
#import "czzBannerNotificationUtil.h"

@interface czzFeedbackViewController ()
@property UIViewController *topController;
@end

@implementation czzFeedbackViewController
@synthesize myFeedback;
@synthesize myNotification;
@synthesize contentTextView;
@synthesize topController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (myNotification) {
        self.title = [NSString stringWithFormat:@"反馈:%@", myNotification.title];
    } else {
        self.title = @"反馈";
    }
    // observe keyboard hide and show notifications to resize the text view appropriately
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    myFeedback = [czzFeedback new];
    contentTextView.inputAccessoryView = [self makeToolBar];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [contentTextView becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [contentTextView resignFirstResponder];
}

#pragma Keyboard actions
-(void)keyboardWillShow:(NSNotification*)notification{
    /*
     Reduce the size of the text view so that it's not obscured by the keyboard.
     Animate the resize so that it's in sync with the appearance of the keyboard.
     */
    
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the origin of the keyboard when it's displayed.
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    // Get the top of the keyboard as the y coordinate of its origin in self's view's
    // coordinate system. The bottom of the text view's frame should align with the top
    // of the keyboard's final position.
    //
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGFloat keyboardTop = keyboardRect.origin.y;
    CGRect newTextViewFrame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y/* + self.navigationController.navigationBar.frame.size.height*/, self.view.bounds.size.width, self.view.bounds.size.height);
    newTextViewFrame.size.height = keyboardTop - self.view.bounds.origin.y;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    contentTextView.frame = newTextViewFrame;
    
    [UIView commitAnimations];
}

-(void)keyboardWillHide:(NSNotification*)notification{
    NSDictionary *userInfo = [notification userInfo];
    
    /*
     Restore the size of the text view (fill self's view).
     Animate the resize so that it's in sync with the disappearance of the keyboard.
     */
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    contentTextView.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y/* + self.navigationController.navigationBar.frame.size.height*/, self.view.bounds.size.width, self.view.bounds.size.height);
    
    [UIView commitAnimations];
}

-(UIToolbar*)makeToolBar {
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    toolbar.barStyle = UIBarStyleDefault;
    toolbar.backgroundColor = toolbar.barTintColor = [settingCentre barTintColour];
    toolbar.tintColor = [settingCentre tintColour];
    //assign an input accessory view to it
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
//    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *plusEmotionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"happy.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(plusAction:)];
    UIBarButtonItem *minusEmotionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sad.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(minusAction:)];
    UIBarButtonItem *postButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sent.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(sendAction:)];
    NSArray *buttons = [NSArray arrayWithObjects: flexibleSpace,
                        plusEmotionButton,
                        flexibleSpace,
                        minusEmotionButton,
                        flexibleSpace,
                        postButton,
                        nil];
    toolbar.items = buttons;
    return toolbar;
}

- (IBAction)plusAction:(id)sender {
    myFeedback.emotion = happy;
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"happy.png"]];
    imgView.frame = CGRectMake(0, 0, 60, 60);
    imgView.backgroundColor = [UIColor whiteColor];
    
    [self.view showToast:imgView duration:1.5 position:@"top"];
}

- (IBAction)minusAction:(id)sender {
    myFeedback.emotion = sad;
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sad.png"]];
    imgView.frame = CGRectMake(0, 0, 60, 60);
    imgView.backgroundColor = [UIColor whiteColor];
    
    [self.view showToast:imgView duration:1.5 position:@"top"];

}

- (IBAction)sendAction:(id)sender {
    myFeedback.content = contentTextView.text;
    [contentTextView resignFirstResponder];
    if (contentTextView.text.length <= 0) {
        [czzBannerNotificationUtil displayMessage:@"请输入内容" position:BannerNotificationPositionTop];
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([myFeedback sendFeedback:myNotification]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                DDLogDebug(@"feedback sent");
                [self.navigationController popViewControllerAnimated:YES];
                [AppDelegate.window makeToast:@"谢谢你的意见！" duration:1.5 position:@"bottom"];
            });
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                DDLogDebug(@"feedback sent");
                [self.navigationController popViewControllerAnimated:YES];
                [czzBannerNotificationUtil displayMessage:@"无法发送，请到我的主页直接给我留言" position:BannerNotificationPositionTop];
            });
        }
    });
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"NotificationCentreStoryBoard" bundle:nil] instantiateViewControllerWithIdentifier:@"feedback_view_controller"];
}
@end
