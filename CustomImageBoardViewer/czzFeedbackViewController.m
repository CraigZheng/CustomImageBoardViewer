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
#import "Toast+UIView.h"

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
    if (self.viewDeckController) {
        topController = self.viewDeckController.topController;
        self.viewDeckController.topController = nil;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [contentTextView resignFirstResponder];
    if (self.viewDeckController && topController) {
        self.viewDeckController.topController = topController;
    }
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
    toolbar.barStyle = UIBarStyleBlack;
    
    //assign an input accessory view to it
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *pickEmojiButton = [[UIBarButtonItem alloc] initWithTitle:@"+1" style:UIBarButtonItemStyleBordered target:self action:@selector(plusAction:)];
    UIBarButtonItem *pickImgButton = [[UIBarButtonItem alloc] initWithTitle:@"-1" style:UIBarButtonItemStyleBordered target:self action:@selector(minusAction:)];
    UIBarButtonItem *postButton = [[UIBarButtonItem alloc] initWithTitle:@"发表" style:UIBarButtonItemStyleBordered target:self action:@selector(sendAction:)];
    NSArray *buttons = [NSArray arrayWithObjects: pickEmojiButton, pickImgButton, flexibleSpace, postButton, nil];
    toolbar.items = buttons;
    return toolbar;
}

- (IBAction)plusAction:(id)sender {
    myFeedback.emotion = happy;
    [self.view makeToast:nil duration:1.5 position:@"top" image:[UIImage imageNamed:@"emotion_smile_icon.png"]];
}

- (IBAction)minusAction:(id)sender {
    myNotification.emotion = sad;
    [self.view makeToast:nil duration:1.5 position:@"top" image:[UIImage imageNamed:@"emotion_sad_icon.png"]];

}

- (IBAction)sendAction:(id)sender {
    myFeedback.content = contentTextView.text;
    [contentTextView resignFirstResponder];
    if (contentTextView.text.length <= 0) {
        [self.view makeToast:@"请输入内容" duration:1.5 position:@"bottom"];
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([myFeedback sendFeedback:myNotification]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"feedback sent");
                [self.navigationController popViewControllerAnimated:YES];
                [[czzAppDelegate sharedAppDelegate].window makeToast:@"谢谢你的意见！" duration:1.5 position:@"bottom"];
            });
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"feedback sent");
                [self.navigationController popViewControllerAnimated:YES];
                [self.view makeToast:@"无法发送，请到我的主页直接给我留言" duration:1.5 position:@"bottom"];
            });
        }
    });
}


@end
