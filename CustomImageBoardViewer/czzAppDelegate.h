//
//  czzAppDelegate.h
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IIViewDeckController.h"
#import "czzHomeViewController.h"

//the host will be changed very soon
#define my_main_host @"http://civ.atwebpages.com/"
#define my_backup_host @"http://civ.my-realm.com/"

@interface czzAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property BOOL shouldUseBackupServer;
@property (nonatomic) NSString *myhost;
@property czzHomeViewController *homeViewController; //this is pretty much the root of the whole app.

-(void)showToast:(NSString*)string;
+ (czzAppDelegate*) sharedAppDelegate;
@end
