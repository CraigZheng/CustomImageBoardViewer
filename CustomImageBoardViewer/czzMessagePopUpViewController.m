//
//  czzMessagePopUpViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/01/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzMessagePopUpViewController.h"
#import "KLCPopup.h"

@interface czzMessagePopUpViewController ()
@property KLCPopup *popup;
@end

@implementation czzMessagePopUpViewController
@synthesize popup, messageContentLabel, messageImageView, messageToShow, imageToShow;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


-(void)show  {
    popup = [KLCPopup popupWithContentView:self.view showType:KLCPopupShowTypeBounceIn dismissType:KLCPopupDismissTypeBounceOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:YES dismissOnContentTouch:YES];
    if (messageToShow)
        messageContentLabel.text = messageToShow;
    if (imageToShow)
        messageImageView.image = imageToShow;

    [popup showWithLayout:KLCPopupLayoutCenter];
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:MESSAGE_POPUP_VIEW_CONTROLLER_STORYBOARD_NAME bundle:nil] instantiateInitialViewController];
}
@end
