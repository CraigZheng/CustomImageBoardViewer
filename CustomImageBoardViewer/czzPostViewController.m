//
//  czzPostViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzPostViewController.h"
#import "czzPost.h"
#import "Toast+UIView.h"
#import "SMXMLDocument.h"
#import "czzPostSender.h"
#import "czzAppDelegate.h"

@interface czzPostViewController () <czzPostSenderDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property NSString *targetURLString;
@property NSMutableData *receivedResponse;
@property czzPostSender *postSender;
@end

@implementation czzPostViewController
@synthesize postTextView;
@synthesize postToolbar;
@synthesize thread;
@synthesize replyTo;
@synthesize postNaviBar;
@synthesize targetURLString;
@synthesize postButton;
@synthesize receivedResponse;
@synthesize postSender;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    postTextView.inputAccessoryView = postToolbar;
    self.postNaviBar.topItem.title = [NSString stringWithFormat:@"回复"];
    //URLs
    targetURLString = @"http://h.acfun.tv/api/thread/post_sub";
    //content: reply to
    if (replyTo){
        self.postNaviBar.topItem.title = [NSString stringWithFormat:@"回复:%ld", (long)replyTo.ID];
        postTextView.text = [NSString stringWithFormat:@">>%ld\n\n", (long)replyTo.ID];
    }
    //make a new czzPostSender object, and assign the appropriate target URL and delegate
    postSender = [czzPostSender new];
    postSender.targetURL = [NSURL URLWithString:targetURLString];
    postSender.parentID = thread.ID;
    postSender.delegate = self;
    // observe keyboard hide and show notifications to resize the text view appropriately
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];

}

- (IBAction)postAction:(id)sender {
    postSender.content = postTextView.text;
    [postSender sendPost];
    [postTextView resignFirstResponder];
    [postButton setEnabled:NO];
    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"正在发送..."];
}

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)pickImageAction:(id)sender {
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    [self presentViewController:mediaUI animated:YES completion:nil];
}

//delete everything from the text view
- (IBAction)clearAction:(id)sender {
    postTextView.text = @"";
    [postTextView resignFirstResponder];
}

#pragma UIImagePickerController delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *pickedImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    [postSender setImgData:UIImageJPEGRepresentation(pickedImage, 1.0)];
    [self.view makeToast:@"图片已选" duration:2.0 position:@"center" image:pickedImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma czzPostSender delegate
-(void)statusReceived:(BOOL)status message:(NSString *)message{
    if (status) {
        [self dismissViewControllerAnimated:YES completion:^{
            //dismiss this view controller and upon its dismiss, notify user that the message is posted
            [[czzAppDelegate sharedAppDelegate] showToast:@"帖子已发"];
        }];
    } else {
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:message duration:3.0 position:@"top" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
    }
    [self performSelectorInBackground:@selector(enablePostButton) withObject:Nil];
}

-(void)enablePostButton{
    [postButton setEnabled:YES];
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
    CGRect newTextViewFrame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y + postNaviBar.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
    newTextViewFrame.size.height = keyboardTop - 44 - self.view.bounds.origin.y;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    postTextView.frame = newTextViewFrame;
    
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
    
    postTextView.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y + postNaviBar.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
    
    [UIView commitAnimations];
}

#pragma Orientation change event
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    //set the height of the bar based on device
    //yeah, hard coded, but who cares
    CGRect frame = postNaviBar.frame;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        frame.size.height = 32;
    } else {
        frame.size.height = 44;
    }
    [postNaviBar setFrame:frame];
    
}
@end
