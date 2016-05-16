//
//  czzFavouriteManagerPopUpViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 5/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzFavouriteManagerPopUpViewController.h"

@interface czzFavouriteManagerPopUpViewController ()
@end

@implementation czzFavouriteManagerPopUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated {
//    self.popup = [KLCPopup popupWithContentView:self.view
//                                       showType:KLCPopupShowTypeBounceIn
//                                    dismissType:KLCPopupDismissTypeBounceOut
//                                       maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:NO dismissOnContentTouch:NO];
//
//    [self.popup showWithLayout:KLCPopupLayoutCenter];
    UIPopoverPresentationController *popoverPresentationController;
}

+(instancetype)new {
    return [[UIStoryboard storyboardWithName:@"FavouriteManager" bundle:nil] instantiateInitialViewController];
}

@end
