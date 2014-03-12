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
#import "czzBlacklistSender.h"
#import "czzMenuEnabledTableViewCell.h"
#import "UIViewController+KNSemiModal.h"
#import "czzEmojiCollectionViewController.h"

@interface czzPostViewController () <czzPostSenderDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, czzEmojiCollectionViewControllerDelegate>
@property NSString *targetURLString;
@property NSMutableData *receivedResponse;
@property czzPostSender *postSender;
@end

@implementation czzPostViewController
@synthesize postTextView;
@synthesize thread;
@synthesize replyTo;
@synthesize postNaviBar;
@synthesize targetURLString;
@synthesize postButton;
@synthesize receivedResponse;
@synthesize blacklistEntity;
@synthesize postSender;
@synthesize postMode;
@synthesize forumName;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    postSender = [czzPostSender new];

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
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    toolbar.barStyle = UIBarStyleBlack;
    
    //assign an input accessory view to it
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *pickEmojiButton = [[UIBarButtonItem alloc] initWithTitle:@"颜文字" style:UIBarButtonItemStyleBordered target:self action:@selector(pickEmojiAction:)];
    UIBarButtonItem *pickImgButton = [[UIBarButtonItem alloc] initWithTitle:@"图片" style:UIBarButtonItemStyleBordered target:self action:@selector(pickImageAction:)];
    postButton = [[UIBarButtonItem alloc] initWithTitle:@"发表" style:UIBarButtonItemStyleBordered target:self action:@selector(postAction:)];
    NSArray *buttons = [NSArray arrayWithObjects: flexibleSpace, pickEmojiButton, pickImgButton, postButton, nil];
    toolbar.items = buttons;
    postTextView.inputAccessoryView = toolbar;
    
    //construct the title, content and targetURLString based on selected post mode
    NSString *title = @"回复";
    NSString *content = @"";
    targetURLString = REPLY_POST_URL;
    switch (postMode) {
        case NEW_POST:
            title = @"新帖";
            targetURLString = NEW_POST_URL;
            postSender.forumName = forumName;
            break;
        case REPLY_POST:
            if (self.replyTo)
            {
                title = [NSString stringWithFormat:@"回复:%ld", (long)replyTo.ID];
                content = [NSString stringWithFormat:@">>No.%ld\n\n", (long)replyTo.ID];
            }
            targetURLString = REPLY_POST_URL;
            break;
        case REPORT_POST:
            title = @"举报";
            targetURLString = NEW_POST_URL;
            postSender.forumName = forumName;
            break;
    }
    self.postNaviBar.topItem.title = title;
    postTextView.text = content;

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //Register focus on text view
    [self.postTextView becomeFirstResponder];
}

- (IBAction)postAction:(id)sender {
    //assign the appropriate target URL and delegate to the postSender
    postSender.targetURL = [NSURL URLWithString:targetURLString];
    postSender.parentID = thread.ID;
    postSender.delegate = self;
    postSender.content = postTextView.text;
    [postSender sendPost];
    [postTextView resignFirstResponder];
    [postButton setEnabled:NO];
    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:@"正在发送..."];
    //if blacklist entity is not nil, then also send a copy to my server
    if (self.blacklistEntity){
        if ([self.blacklistEntity isReady]){
            self.blacklistEntity.reason = postTextView.text;
            czzBlacklistSender *blacklistSender = [czzBlacklistSender new];
            blacklistSender.blacklistEntity = self.blacklistEntity;
            [blacklistSender sendBlacklistUpdate];
        }
    }
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

-(void)pickEmojiAction:(id)sender{
    [postTextView resignFirstResponder];
    czzEmojiCollectionViewController *emojiViewController = [[czzEmojiCollectionViewController alloc] initWithNibName:@"czzEmojiCollectionViewController" bundle:[NSBundle mainBundle]];
    emojiViewController.delegate = self;
    [self presentSemiViewController:emojiViewController withOptions:@{
                                                                      KNSemiModalOptionKeys.pushParentBack    : @(NO),
                                                                      KNSemiModalOptionKeys.animationDuration : @(0.3),
                                                                      KNSemiModalOptionKeys.shadowOpacity     : @(0.0),
                                                                      }];
}

//delete everything from the text view
- (IBAction)clearAction:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"清空内容和图片？" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"清空" otherButtonTitles: nil];
    [actionSheet showInView:self.view];
}

#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
        [self resetContent];
}

-(void)resetContent{
    postTextView.text = @"";
    postSender.imgData = nil;
    [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"内容和图片已清空"];
}

#pragma UIImagePickerController delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *pickedImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    //resize the image if the picked image is too big
    if (pickedImage.size.width > 1280){
        NSInteger newWidth = 1280;
        NSInteger newHeight = (newWidth / pickedImage.size.width) * pickedImage.size.height;
        pickedImage = [self resizeImage:pickedImage width:newWidth height:newHeight];
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"由于图片尺寸太大，已进行压缩" duration:1.5 position:@"top" title:@"图片已选" image:pickedImage];
    } else {
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"图片已选" duration:1.5 position:@"top" image:pickedImage];
    }

    [postSender setImgData:UIImageJPEGRepresentation(pickedImage, 0.8)];
    [picker dismissViewControllerAnimated:YES completion:^{
        [postTextView becomeFirstResponder];
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:^{
        [postTextView becomeFirstResponder];
    }];
}

#pragma mark - resize UIImage
//copied stright from the almighty internet
-(UIImage *)resizeImage:(UIImage *)image width:(CGFloat)resizedWidth height:(CGFloat)resizedHeight
{
    CGImageRef imageRef = [image CGImage];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(NULL, resizedWidth, resizedHeight, 8, 4 * resizedWidth, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(bitmap, CGRectMake(0, 0, resizedWidth, resizedHeight), imageRef);
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    UIImage *result = [UIImage imageWithCGImage:ref];
    
    CGContextRelease(bitmap);
    CGImageRelease(ref);
    
    return result;
}

#pragma czzPostSender delegate
-(void)statusReceived:(BOOL)status message:(NSString *)message{
    if (status) {
        [self dismissViewControllerAnimated:YES completion:^{
            //dismiss this view controller and upon its dismiss, notify user that the message is posted
            [[czzAppDelegate sharedAppDelegate] showToast:@"帖子已发"];
        }];
    } else {
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:message duration:1.5 position:@"top" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
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

#pragma mark - czzEmojiCollectionViewController delegate
-(void)emojiSelected:(NSString *)emoji{
    UIPasteboard* generalPasteboard = [UIPasteboard generalPasteboard];
	NSArray* items = [generalPasteboard.items copy];
	generalPasteboard.string = emoji;
    [postTextView paste: self];
    generalPasteboard.items = items;
    [self dismissSemiModalViewWithCompletion:^{
        [postTextView becomeFirstResponder];
    }];
}

@end
