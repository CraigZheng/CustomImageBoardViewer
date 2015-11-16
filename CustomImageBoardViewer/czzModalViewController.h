//
//  czzModalViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 16/11/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzFadeInOutModalAnimator.h"

@interface czzModalViewController : UIViewController
@property (nonatomic, strong) czzFadeInOutModalAnimator *modalAnimator;
@property (nonatomic, assign) BOOL dismissOnTap;

-(void)modalShow;

@end
