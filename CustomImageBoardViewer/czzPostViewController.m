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
#import "ValueFormatter.h"
#import "czzForumsViewController.h"
#import "czzForumManager.h"
#import "NSString+HTML.h"
#import "czzSettingsCentre.h"
#import "czzWatchListManager.h"

@interface czzPostViewController () <czzPostSenderDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, czzEmojiCollectionViewControllerDelegate>
@property (nonatomic, strong) NSMutableData *receivedResponse;
@property (nonatomic, strong) czzPostSender *postSender;
@property (nonatomic, strong) czzEmojiCollectionViewController *emojiViewController;

@property (strong, nonatomic) UIBarButtonItem *postButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *postTextViewBottomConstraint;

- (IBAction)clearAction:(id)sender;

@end

@implementation czzPostViewController
@synthesize postTextView;
@synthesize thread;
@synthesize replyTo;
@synthesize postButton;
@synthesize receivedResponse;
@synthesize blacklistEntity;
@synthesize postSender;
@synthesize postMode;
@synthesize forum;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    postSender = [czzPostSender new];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    toolbar.autoresizingMask = toolbar.autoresizingMask | UIViewAutoresizingFlexibleHeight;
    toolbar.barStyle = UIBarStyleDefault;
    toolbar.barTintColor = [settingCentre barTintColour];
    toolbar.tintColor = [settingCentre tintColour];
    //assign an input accessory view to it
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *pickEmojiButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"lol.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(pickEmojiAction:)];
    UIBarButtonItem *pickImgButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"picture.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(pickImageAction:)];
    postButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sent.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(postAction:)];
    NSArray *buttons = [NSArray arrayWithObjects: flexibleSpace,
                        pickEmojiButton,
                        flexibleSpace,
                        pickImgButton,
                        flexibleSpace,
                        postButton, nil];
    toolbar.items = buttons;
    postTextView.inputAccessoryView = toolbar;
    // colour
    postTextView.backgroundColor = [settingCentre viewBackgroundColour];
    postTextView.textColor = [settingCentre contentTextColour];
    postTextView.text = self.prefilledString;
    
    //construct the title, content and targetURLString based on selected post mode
    NSString *title = @"回复";
    NSString *content = @"";
    
    postSender.forum = forum;
    //assign forum or parent thread based on user selection
    NSString *targetURLString;
    switch (postMode) {
        case NEW_POST:
            title = @"新内容";
            postSender.parentThread = nil;
            targetURLString = [[settingCentre create_new_post_url] stringByReplacingOccurrencesOfString:FORUM_NAME withString:forum.name];
            postSender.forum = forum;
            break;
        case REPLY_POST:
            if (self.replyTo)
            {
                title = [NSString stringWithFormat:@"回复:%ld", (long)replyTo.ID];
                content = [NSString stringWithFormat:@">>No.%ld\n\n", (long)replyTo.ID];
            }
            postSender.parentThread = thread;
            break;
        
        case REPORT_POST:
            title = @"举报";
            NSString *forumName = @"值班室";
            targetURLString = [[settingCentre create_new_post_url] stringByReplacingOccurrencesOfString:FORUM_NAME withString:forumName];
            // Select the admin forum from the downloaded forums.
            for (czzForum *tempForum in [czzForumManager sharedManager].forums) {
                if ([tempForum.name isEqualToString:forumName]) {
                    postSender.forum = tempForum;
                    break;
                }
            }
            break;
    }
    self.title = title;
    if (content.length)
        postTextView.text = content;
    
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

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //Register focus on text view
    [self.postTextView becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Dismiss any possible semi modal view.
    if (self.emojiViewController) {
        [self dismissSemiModalView];
    }
}

- (void)postAction:(id)sender {
    //assign the appropriate target URL and delegate to the postSender
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

- (void)pickImageAction:(id)sender {
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    [self presentViewController:mediaUI animated:YES completion:nil];
}

-(void)pickEmojiAction:(id)sender{
    [postTextView resignFirstResponder];
    self.emojiViewController = [[czzEmojiCollectionViewController alloc] initWithNibName:@"czzEmojiCollectionViewController" bundle:[NSBundle mainBundle]];
    self.emojiViewController.delegate = self;
    [self presentSemiViewController:self.emojiViewController
                        withOptions:@{
                                      KNSemiModalOptionKeys.pushParentBack    : @(NO),
                                      KNSemiModalOptionKeys.animationDuration : @(0.3),
                                      KNSemiModalOptionKeys.shadowOpacity     : @(0.0),
                                      }
                         completion:nil
                       dismissBlock:^{
                           self.emojiViewController = nil;
                       }];
}

//delete everything from the text view
- (IBAction)clearAction:(id)sender {
    if (postTextView.text.length > 0)
    {
        [self.postTextView resignFirstResponder];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"清空内容和图片？" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"清空" otherButtonTitles: nil];
        [actionSheet showInView:self.view];

    }
}

-(void)resetContent{
    postTextView.text = @"";
    postSender.imgData = nil;
    [[AppDelegate window] makeToast:@"内容和图片已清空"];
}

#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    [self resetContent];
}

#pragma UIImagePickerController delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *pickedImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation(pickedImage, 0.85);
    NSString *titleWithSize = [ValueFormatter convertByte:imageData.length];
    //resize the image if the picked image is too big
    if (pickedImage.size.width * pickedImage.size.height > 1920 * 1080){
        NSInteger newWidth = 1080;
        pickedImage = [self imageWithImage:pickedImage scaledToWidth:newWidth];
        [[AppDelegate window] makeToast:@"由于图片尺寸太大，已进行压缩" duration:1.5 position:@"top" title:titleWithSize image:pickedImage];
    } else {
        [[AppDelegate window] makeToast:titleWithSize duration:1.5 position:@"top" image:pickedImage];
    }
    
    [postSender setImgData:imageData];
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

-(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width
{
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma czzPostSender delegate
-(void)statusReceived:(BOOL)status message:(NSString *)message{
    if (status) {
        [self.navigationController popViewControllerAnimated:YES];
        [AppDelegate showToast:@"提交成功"];
        
        if (postSender.parentThread) {
            [WatchListManager addToRespondedList:self.thread];
        }
    } else {
        [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:message duration:1.5 position:@"top" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
        self.title = message.length > 0 ? message : @"出错，没有更多信息";
    }
    [self enablePostButton];
}

-(void)enablePostButton{
    [postButton setEnabled:YES];
}

-(void)postSenderProgressUpdated:(CGFloat)percent {
    self.title = [NSString stringWithFormat:@"发送中 - %d%%", (int)(percent * 100)];
}

#pragma mark - Keyboard events.
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
    
    CGFloat keyboardTop = keyboardRect.size.height;

    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    self.postTextViewBottomConstraint.constant = keyboardTop;
    
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
    
    self.postTextViewBottomConstraint.constant = 0;
    
    [UIView commitAnimations];
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

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"post_view_controller"];
}

@end
