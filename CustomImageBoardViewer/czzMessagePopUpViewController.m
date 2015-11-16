//
//  czzMessagePopUpViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/01/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzMessagePopUpViewController.h"

@implementation czzMessagePopUpViewController
@synthesize messageContentLabel, messageImageView, messageToShow, imageToShow;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)modalShow {
    if (messageToShow)
        messageContentLabel.text = messageToShow;
    if (imageToShow)
        messageImageView.image = imageToShow;
    [super modalShow];
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:MESSAGE_POPUP_VIEW_CONTROLLER_STORYBOARD_NAME bundle:nil] instantiateInitialViewController];
}
@end
