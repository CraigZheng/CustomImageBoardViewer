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
#import "UIViewController+KNSemiModal.h"
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
#import <AssetsLibrary/AssetsLibrary.h>

@interface czzPostViewController () <UINavigationControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, czzEmojiCollectionViewControllerDelegate>
@property (nonatomic, strong) UIActionSheet *clearContentActionSheet;
@property (nonatomic, strong) UIActionSheet *cancelPostingActionSheet;
@property (nonatomic, strong) NSMutableData *receivedResponse;
@property (nonatomic, strong) czzPostSender *postSender;
@property (nonatomic, strong) czzEmojiCollectionViewController *emojiViewController;
@property (nonatomic, assign) BOOL didLayout;
@property (strong, nonatomic) UIBarButtonItem *postButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *postTextViewBottomConstraint;

- (IBAction)clearAction:(id)sender;

@end

@implementation czzPostViewController
@synthesize postTextView;
@synthesize postButton;
@synthesize receivedResponse;
@synthesize blacklistEntity;
@synthesize postSender;
@synthesize postMode;
@synthesize forum;

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
    // Dismiss any possible semi modal view.
    if (self.emojiViewController) {
        [self dismissSemiModalView];
    }
}

- (void)renderContent {
    postSender = [czzPostSender new];
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
                        postButton, nil];
    toolbar.items = buttons;
    postTextView.inputAccessoryView = toolbar;
    // colour
    postTextView.backgroundColor = [settingCentre viewBackgroundColour];
    postTextView.textColor = [settingCentre contentTextColour];
    postTextView.text = self.prefilledString;
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
                                          image:[UIImage imageWithData:self.displayPostSender.imgData]];
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
    
    postSender.forum = forum;
    //assign forum or parent thread based on user selection
    NSString *targetURLString;
    switch (postMode) {
        case postViewControllerModeNew:
            title = @"新内容";
            postSender.parentThread = nil;
            targetURLString = [[settingCentre create_new_post_url] stringByReplacingOccurrencesOfString:FORUM_NAME withString:forum.name];
            postSender.forum = forum;
            postSender.postMode = postSenderModeNew;
            break;
        case postViewControllerModeReply:
            if (self.replyToThread)
            {
                title = [NSString stringWithFormat:@"回复:%ld", (long)self.replyToThread.ID];
                content = [NSString stringWithFormat:@">>No.%ld\n\n", (long)self.replyToThread.ID];
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
    self.title = title;
    if (content.length)
        postTextView.text = content;
    // Already layout contents.
    self.didLayout = YES;
}

- (void)postAction:(id)sender {
    //assign the appropriate target URL and delegate to the postSender
    postSender.content = postTextView.text;
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
    NSString *label = self.postSender.content;
    // Chunk the text.
    if (label.length > 100) {
        label = [label substringToIndex:99];
    }
    NSInteger ID = postSender.parentThread ? postSender.parentThread.ID : 0;
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Thread"
                                                                                        action:@"Post Thread"
                                                                                         label:label
                                                                                         value:@(ID)] build]];

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
    if ((postTextView.text.length > 0 || postSender.imgData) &&
        postMode != postViewControllerModeDisplayOnly)
    {
        [self.postTextView resignFirstResponder];
        self.clearContentActionSheet = [[UIActionSheet alloc] initWithTitle:@"清空内容和图片？" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"清空" otherButtonTitles: nil];
        [self.clearContentActionSheet showInView:self.view];

    }
}

- (IBAction)cancelAction:(id)sender {
    if ((postTextView.text.length || postSender.imgData) &&
        postMode != postViewControllerModeDisplayOnly) {
        [self.postTextView resignFirstResponder];
        self.cancelPostingActionSheet = [[UIActionSheet alloc] initWithTitle:@"确定要中断发送文章？" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"中断" otherButtonTitles: nil];
        [self.cancelPostingActionSheet showInView:self.view];
    } else
        [self dismissWithCompletionHandler:nil];
}

-(void)resetContent{
    postTextView.text = @"";
    [postSender setImgData:nil format:nil];
    [czzBannerNotificationUtil displayMessage:@"内容和图片已清空"
                                     position:BannerNotificationPositionTop];
}

- (void)dismissWithCompletionHandler:(void(^)(void))completionHandler {
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

#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (actionSheet == self.clearContentActionSheet) {
        if (buttonIndex == actionSheet.destructiveButtonIndex)
            [self resetContent];
    } else if (actionSheet == self.cancelPostingActionSheet) {
        if (buttonIndex == actionSheet.destructiveButtonIndex)
            [self dismissWithCompletionHandler:nil];
    }
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
            [postSender setImgData:assetData format:@"gif"];
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
        NSData *imageData = UIImageJPEGRepresentation(pickedImage, 0.85);
        NSString *titleWithSize = [ValueFormatter convertByte:imageData.length];
        //resize the image if the picked image is too big
        CGFloat scale = pickedImage.size.width * pickedImage.size.height / (1920 * 1080);
        if (scale > 1){
            NSInteger newWidth = pickedImage.size.width / scale;
            pickedImage = [self imageWithImage:pickedImage scaledToWidth:newWidth];
            [[AppDelegate window] makeToast:@"由于图片尺寸太大，已进行压缩" duration:1.5 position:@"top" title:titleWithSize image:pickedImage];
        } else {
            [[AppDelegate window] makeToast:titleWithSize duration:1.5 position:@"top" image:pickedImage];
        }
        // No need to specify the format
        [postSender setImgData:imageData format:nil];
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

-(void)enablePostButton{
    [postButton setEnabled:YES];
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
