//
//  czzAppDelegate.h
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IIViewDeckController.h"

//the host will be changed very soon
//#define myhost @"http://civ.atwebpages.com/"
#define myhost @"http://civ.my-realm.com/"

@interface czzAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

-(void)showToast:(NSString*)string;
+ (czzAppDelegate*) sharedAppDelegate;
@end
