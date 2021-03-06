//
//  czzPostViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 29/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzPostViewController.h"

#import "NSString+HTML.h"
#import "SMXMLDocument.h"
#import "czzPost.h"
#import "SMXMLDocument.h"
#import "Toast+UIView.h"
#import "ValueFormatter.h"
#import "czzAppDelegate.h"
#import "czzBlacklistSender.h"
#import "czzEmojiCollectionViewController.h"
#import "czzForumManager.h"
#import "czzForumsViewController.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzPost.h"
#import "czzPostSender.h"
#import "czzSettingsCentre.h"
#import "czzThreadDownloader.h"
#import "czzHistoryManager.h"
#import "czzBannerNotificationUtil.h"
#import "czzPostSenderManager.h"
#import "CustomImageBoardViewer-Swift.h"
#import <AssetsLibrary/AssetsLibrary.h>

static CGFloat compressScale = 0.9;
static NSString *kDraftSelectorSegue = @"draftSelector";
static NSString *kPostEmailKey = @"kPostEmailKey";
static NSString *kPostNameKey = @"kPostNameKey";

@interface czzPostViewController () <UIPopoverPresentationControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, czzEmojiCollectionViewControllerDelegate, DraftSelectorTableViewControllerDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UIActionSheet *cancelPostingActionSheet;
@property (nonatomic, strong) UIAlertView *watermarkAlertView;
@property (nonatomic, strong) NSMutableData *receivedResponse;
@property (nonatomic, strong) czzEmojiCollectionViewController *emojiViewController;
@property (nonatomic, weak) DraftSelectorTableViewController *draftSelectorViewController;
@property (nonatomic, assign) BOOL didLayout;
@property (strong, nonatomic) UIBarButtonItem *postButton;
@property (weak, nonatomic) IBOutlet UIImageView *postImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *postTextViewBottomConstraint;

@property (nonatomic, strong) NSData *pickedImageData;
@property (nonatomic, strong) UIBarButtonItem *keyboardBarButtonItem;
@property (nonatomic, strong) NSString *pickedImageFormat;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) NSObject *observation;

@end

@implementation czzPostViewController
@synthesize postTextView;
@synthesize postButton;
@synthesize receivedResponse;
@synthesize blacklistEntity;
@synthesize postSender;
@synthesize postMode;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // observe keyboard hide and show notifications to resize the text view appropriately
    [[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    __weak typeof(self) weakSelf = self;
    self.observation = [[NSNotificationCenter defaultCenter] addObserverForName:settingsChangedNotification
                                                                         object:nil
                                                                          queue:nil
                                                                     usingBlock:^(NSNotification * _Nonnull note) {
        [weakSelf renderContent];
    }];
    // If there're drafts available for selecting, show them here.
    if ([DraftManager count] && settingCentre.userDefShouldShowDraft) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:kDraftSelectorSegue sender:nil];
        });
    }
    if ([NSUserDefaults.standardUserDefaults stringForKey:kPostNameKey].length > 0) {
        self.nameTextField.text = [NSUserDefaults.standardUserDefaults stringForKey:kPostNameKey];
    }
    if ([NSUserDefaults.standardUserDefaults stringForKey:kPostEmailKey].length > 0) {
        self.emailTextField.text = [NSUserDefaults.standardUserDefaults stringForKey:kPostEmailKey];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.didLayout) {
        [self renderContent];
    }
    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //Register focus on text view
    [self.postTextView becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSUserDefaults.standardUserDefaults setObject:self.nameTextField.text forKey:kPostNameKey];
    [NSUserDefaults.standardUserDefaults setObject:self.emailTextField.text forKey:kPostEmailKey];
}

#pragma mark - Prepare for segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kDraftSelectorSegue] && [segue.destinationViewController isKindOfClass:[DraftSelectorTableViewController class]]) {
        self.draftSelectorViewController = segue.destinationViewController;
        self.draftSelectorViewController.popoverPresentationController.delegate = self;
        self.draftSelectorViewController.popoverPresentationController.sourceView = self.view;
        self.draftSelectorViewController.popoverPresentationController.sourceRect = self.view.bounds;
        self.draftSelectorViewController.delegate = self;
    }
}

#pragma marl - UIPopoverPresentationControllerDelegate.

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (void)renderContent {
    if (self.didLayout) {
        return;
    }
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    toolbar.autoresizingMask = toolbar.autoresizingMask | UIViewAutoresizingFlexibleHeight;
    toolbar.barStyle = UIBarStyleDefault;
    toolbar.barTintColor = [settingCentre barTintColour];
    toolbar.tintColor = [settingCentre tintColour];
    //assign an input accessory view to it
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    UIBarButtonItem *pickEmojiButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"lol.png"]
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(pickEmojiAction:)];
    UIBarButtonItem *pickImgButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"picture.png"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(pickImageAction:)];
    postButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sent.png"]
                                                  style:UIBarButtonItemStylePlain
                                                 target:self
                                                 action:@selector(postAction:)];
    NSArray *buttons = [NSArray arrayWithObjects: flexibleSpace,
                        pickEmojiButton,
                        flexibleSpace,
                        pickImgButton,
                        flexibleSpace,
                        self.keyboardBarButtonItem,
                        flexibleSpace,
                        postButton, nil];
    toolbar.items = buttons;
    postTextView.inputAccessoryView = toolbar;
    // colour
    self.view.backgroundColor = [settingCentre viewBackgroundColour];
    postTextView.backgroundColor = [UIColor clearColor];
    if (@available(iOS 13.0, *)) {
        postTextView.textColor = UIColor.labelColor;
    } else {
        postTextView.textColor = [settingCentre contentTextColour];
    }
    postTextView.text = self.prefilledString;
    // Adjust textview shadow.
    postTextView.layer.shadowColor = [UIColor whiteColor].CGColor;
    postTextView.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    postTextView.layer.shadowOpacity = 1.0;
    postTextView.layer.shadowRadius = 2.0;
    
    // If is display only mode, show the content and then return.
    if (postMode == postViewControllerModeDisplayOnly) {
        assert(self.displayPostSender);
        if (self.displayPostSender) {
            self.title = self.displayPostSender.title;
            self.postTextView.text = self.displayPostSender.content;
            self.postTextView.editable = NO; // No editable.
            // Show the picked image.
            if (self.displayPostSender.imgData) {
                [[AppDelegate window] makeToast:nil
                                       duration:1.5
                                       position:@"top"
                                          image:nil];
                self.postImageView.image = [UIImage imageWithData:self.displayPostSender.imgData];
            }
            for (UIBarButtonItem *button in buttons) {
                button.enabled = NO;
            }
        }
        // Since is display only, no need to go any further.
        return;
    }
    //construct the title, content and targetURLString based on selected post mode
    NSString *title = @"回复";
    NSString *content = @"";
    NSString *targetURLString;

    if (postSender) {
        // If the post sender is ready.
        targetURLString = postSender.targetURL.absoluteString;
        content = postSender.content;
        // The title should respond to the post sender mode.
        switch (postSender.postMode) {
            case postSenderModeNew:
                title = @"新内容";
                break;
            case postSenderModeReply:
                title = [NSString stringWithFormat:@"回复:%ld", (long)postSender.parentThread.ID];
                break;
            default:
                [NSException raise:@"UNSUPPORTED ACTION" format:@""];
                break;
        }
    } else {
        // Construct a new post sender object.
        postSender = [czzPostSender new];
        postSender.forum = self.forum;
        switch (postMode) {
            case postViewControllerModeNew:
                title = @"新内容";
                postSender.parentThread = nil;
                targetURLString = [[settingCentre create_new_post_url] stringByReplacingOccurrencesOfString:FORUM_NAME withString:self.forum.name];
                postSender.forum = self.forum;
                postSender.postMode = postSenderModeNew;
                break;
            case postViewControllerModeReply:
                if (self.replyToThread)
                {
                    title = [NSString stringWithFormat:@"回复:%ld", (long)self.replyToThread.ID];
                    if (settingCentre.reply_post_placeholder.length) {
                        content = [NSString stringWithFormat:settingCentre.reply_post_placeholder, (long) self.replyToThread.ID];
                    } else {
                        content = [NSString stringWithFormat:@">>No.%ld\n\n", (long)self.replyToThread.ID];
                    }
                }
                postSender.parentThread = self.parentThread;
                postSender.postMode = postSenderModeReply;
                break;
                
            case postViewControllerModeReport: {
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
                postSender.postMode = postSenderModeNew;
                break;
            }
            default:
                [NSException raise:@"ACTION NOT SUPPORTED" format:@"%s", __func__];
                break;
        }
    }
    self.title = title;
    if (content.length)
        postTextView.text = content;
    // Already layout contents.
    self.didLayout = YES;
}

#pragma mark - UI actions.

- (void)keyboardAction:(id)sender {
    [self.draftSelectorViewController dismissViewControllerAnimated:NO completion:nil];
    if ([self.postTextView isFirstResponder]) {
        [self.postTextView resignFirstResponder];
    } else {
        [self.postTextView becomeFirstResponder];
    }
}

- (void)postAction:(id)sender {
    [self.draftSelectorViewController dismissViewControllerAnimated:NO completion:nil];
    postSender.content = postTextView.text;
    postSender.name = self.nameTextField.text.length > 0 ? self.nameTextField.text : nil;
    postSender.email = self.emailTextField.text.length > 0 ? self.emailTextField.text : nil;
    if (postSender.content.length != 0 || postSender.imgData != nil) {
        // Let post sender manager handles the post sender in the background.
        [PostSenderManager firePostSender:postSender];
        [postTextView resignFirstResponder];
        [postButton setEnabled:NO];
        [self dismissWithCompletionHandler:^{
            [czzBannerNotificationUtil displayMessage:@"正在发送..."
                                             position:BannerNotificationPositionTop];
        }];
        //if blacklist entity is not nil, then also send a copy to my server
        if (self.blacklistEntity){
            if ([self.blacklistEntity isReady]){
                self.blacklistEntity.reason = postTextView.text;
                czzBlacklistSender *blacklistSender = [czzBlacklistSender new];
                blacklistSender.blacklistEntity = self.blacklistEntity;
                [blacklistSender sendBlacklistUpdate];
            }
        }
        
        // Google Analytic integration.
        NSString *label = @"Post Text";
        // Chunk the text.
        if (self.postSender.imgData) {
            label = @"Post Image";
        }
        [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Thread"
                                                                                            action:@"Post Thread"
                                                                                             label:label
                                                                                             value:@1] build]];
    } else {
        [czzBannerNotificationUtil displayMessage:@"请检查内容" position:BannerNotificationPositionTop];
    }
}

- (void)pickImageAction:(id)sender {
    [self.draftSelectorViewController dismissViewControllerAnimated:NO completion:nil];
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    // Reset image contents.
    self.pickedImageFormat = nil;
    self.pickedImageData = nil;
    [self presentViewController:mediaUI animated:YES completion:nil];
}

-(void)pickEmojiAction:(id)sender{
    [postTextView resignFirstResponder];
    self.emojiViewController = [[czzEmojiCollectionViewController alloc] initWithNibName:@"czzEmojiCollectionViewController" bundle:[NSBundle mainBundle]];
    self.emojiViewController.delegate = self;
    self.emojiViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:self.emojiViewController animated:true completion:nil];
}

- (IBAction)cancelAction:(id)sender {
  if ((postTextView.text.length || postSender.imgData) &&
      postMode != postViewControllerModeDisplayOnly) {
    [self.postTextView resignFirstResponder];
    self.cancelPostingActionSheet = [[UIActionSheet alloc] initWithTitle:@"确定要中断发送文章？" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"中断" otherButtonTitles:@"中断并保存草稿", nil];
    [self.cancelPostingActionSheet showInView:self.view];
  } else
    [self dismissWithCompletionHandler:nil];
}

- (void)textViewDidChange:(UITextView *)textView {
    [self.draftSelectorViewController dismissViewControllerAnimated:NO completion:nil];
}

-(void)resetContent{
    postTextView.text = @"";
    self.pickedImageData = nil;
    self.pickedImageFormat = nil;
    [czzBannerNotificationUtil displayMessage:@"内容和图片已清空"
                                     position:BannerNotificationPositionTop];
}

- (void)dismissWithCompletionHandler:(void(^)(void))completionHandler {
    [self.draftSelectorViewController dismissViewControllerAnimated:NO completion:nil];
    BOOL isModalView = [self isModal];
    if (self.navigationController.viewControllers.count > 1) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            if (completionHandler) {
                completionHandler();
            }
        }];
        
        [self.navigationController popViewControllerAnimated:YES];
        [CATransaction commit];
        
    } else if (isModalView) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            if (completionHandler) {
                completionHandler();
            }
        }];
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.nameTextField) {
        [self.emailTextField becomeFirstResponder];
    } else if (textField == self.emailTextField) {
        [self.postTextView becomeFirstResponder];
    }
    return NO;
}

#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
  if (actionSheet == self.cancelPostingActionSheet) {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
      return;
    }
    if (buttonIndex != actionSheet.destructiveButtonIndex) {
      [DraftManager save:postTextView.text];
    }
    [self dismissWithCompletionHandler:nil];
  }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView == self.watermarkAlertView && buttonIndex != self.watermarkAlertView.cancelButtonIndex) {
        postSender.watermark = YES;
    }
}

#pragma mark - DraftSelectorTableViewControllerDelegate

- (void)draftSelector:(DraftSelectorTableViewController *)viewController selectedContent:(NSString *)selectedContent {
  [viewController dismissViewControllerAnimated:NO completion:nil];
  if (selectedContent.length) {
    [self.postTextView replaceRange:self.postTextView.selectedTextRange withText:selectedContent];
    [DraftManager delete:selectedContent];
  }
}

#pragma mark - Setters

- (void)setPickedImageData:(NSData *)pickedImageData {
    _pickedImageData = pickedImageData;
    if (postSender) {
        [postSender setImgData:_pickedImageData format:self.pickedImageFormat];
        postSender.watermark = NO;
    }
    // Show content on screen.
    self.postImageView.image = [UIImage imageWithData:pickedImageData];
}

#pragma mark - Getters

- (UIBarButtonItem *)keyboardBarButtonItem {
    if (!_keyboardBarButtonItem) {
        _keyboardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"keyboard.png"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(keyboardAction:)];
    }
    return _keyboardBarButtonItem;
}

#pragma UIImagePickerController delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *pickedImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    NSURL *originalURL = [info valueForKey:UIImagePickerControllerReferenceURL];

    // Gif image, need to load from ALAssets representation.
    if ([originalURL.pathExtension.lowercaseString isEqualToString:@"gif"]) {
        [[ALAssetsLibrary new] assetForURL:originalURL resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            Byte *buffer = (Byte*)malloc(rep.size);
            NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
            NSData *assetData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
            self.pickedImageData = assetData;
            self.pickedImageFormat = @"gif";
            [[AppDelegate window] makeToast:[NSString stringWithFormat:@"%@", originalURL.lastPathComponent]
                                   duration:1.5
                                   position:@"top"
                                      title:nil
                                      image:pickedImage];
        } failureBlock:^(NSError *error) {
            DDLogDebug(@"%@", error);
        }];
    } else {
        // JPG or PNG image, upload straight away.
        NSData *imageData = UIImageJPEGRepresentation(pickedImage, compressScale);
        NSString *titleWithSize = [ValueFormatter convertByte:imageData.length];
        //resize the image if the picked image is too big
        CGFloat scale = pickedImage.size.width * pickedImage.size.height / settingCentre.upload_image_pixel_limit;
        if (scale > 1){
            CGFloat scaleFactor = sqrt(scale);
            NSInteger newLongEdge = MAX(pickedImage.size.width, pickedImage.size.height) / scaleFactor;
            pickedImage = [self imageWithImage:pickedImage scaleLongEdgeTo:newLongEdge];
            NSString *newSizeString = [ValueFormatter convertByte:UIImageJPEGRepresentation(pickedImage, compressScale).length];
            [[AppDelegate window] makeToast:[NSString stringWithFormat:@"%@ -> %@", titleWithSize, newSizeString]
                                   duration:1.5
                                   position:@"top"
                                      title:@"由于图片尺寸太大，已进行压缩"
                                      image:pickedImage];
            imageData = UIImageJPEGRepresentation(pickedImage, compressScale);
        } else {
            [[AppDelegate window] makeToast:titleWithSize duration:1.5 position:@"top" image:pickedImage];
        }
        imageData = UIImageJPEGRepresentation(pickedImage, compressScale);
        // No need to specify the format
        self.pickedImageData = imageData;
        // Confirm watermark.
        self.watermarkAlertView = [[UIAlertView alloc] initWithTitle:nil message:@"是否包含水印？" delegate:self cancelButtonTitle:@"否" otherButtonTitles:@"是", nil];
        [self.watermarkAlertView show];
    }
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

-(UIImage*)imageWithImage: (UIImage*) sourceImage scaleLongEdgeTo: (float) newLongEdge
{
    float scaleFactor = newLongEdge / MAX(sourceImage.size.width, sourceImage.size.height);
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = sourceImage.size.width * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(void)enablePostButton{
    [postButton setEnabled:YES];
}

#pragma mark - Keyboard events.
-(void)keyboardWillShow:(NSNotification*)notification{
    [self.draftSelectorViewController dismissViewControllerAnimated:NO completion:nil];
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
    [self.draftSelectorViewController dismissViewControllerAnimated:NO completion:nil];
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
    [self.postTextView replaceRange:self.postTextView.selectedTextRange withText:emoji];
    [self dismissViewControllerAnimated:true completion:^{
        [postTextView becomeFirstResponder];
    }];
}

- (void)emoticonSelected:(UIImage *)emoticon {
    self.pickedImageData = UIImageJPEGRepresentation(emoticon, 1);
    [self dismissViewControllerAnimated:true completion:^ {
        [postTextView becomeFirstResponder];
    }];
}

#pragma mark - UIStateRestoring

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    if (self.parentThread) {
        [coder encodeObject:self.parentThread forKey:@"parentThread"];
    }
    if (self.replyToThread) {
        [coder encodeObject:self.replyToThread forKey:@"replyToThread"];
    }
    if (self.forum) {
        [coder encodeObject:self.forum forKey:@"forum"];
    }
    [coder encodeInteger:self.postMode forKey:@"postMode"];
    [coder encodeObject:self.postTextView.text forKey:@"postTextView.text"];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    czzThread *parentThread = [coder decodeObjectForKey:@"parentThread"];
    czzThread *replyToThread = [coder decodeObjectForKey:@"replyToThread"];
    czzForum *forum = [coder decodeObjectForKey:@"forum"];
    if ([parentThread isKindOfClass:[czzThread class]]) {
        self.parentThread = parentThread;
    }
    if ([replyToThread isKindOfClass:[czzThread class]]) {
        self.replyToThread = replyToThread;
    }
    if ([forum isKindOfClass:[czzForum class]]) {
        self.forum = forum;
    }
    self.postMode = [coder decodeIntegerForKey:@"postMode"];
    self.prefilledString = [coder decodeObjectForKey:@"postTextView.text"];
}

+ (instancetype)new {
    return [[UIStoryboard storyboardWithName:@"PostView" bundle:nil] instantiateViewControllerWithIdentifier:@"post_view_controller"];
}

@end
