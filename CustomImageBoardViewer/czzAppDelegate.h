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
#import "NSObject+Extension.h"

//the host will be changed very soon
#define my_main_host @"www.my-realm.com"
#define my_backup_host @"http://civ.atwebpages.com/"

// Manager singleton
#define AppDelegate [czzAppDelegate sharedAppDelegate]

@interface czzAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (assign, nonatomic) BOOL shouldUseBackupServer;
@property (strong, nonatomic) NSString *myhost;
@property (strong, nonatomic) NSString *vendorID;

-(void)showToast:(NSString*)string;
+ (czzAppDelegate*) sharedAppDelegate;
+(NSString*)libraryFolder;
+(NSString*)thumbnailFolder;
+(NSString*)imageFolder;
+(NSString*)threadCacheFolder;
+(NSString*)notificationCacheFolder;

-(void)checkFolders;
-(void)doSingleViewHideAnimation:(UIView*)incomingView :(NSString*)animType :(CGFloat)duration;
-(void)doSingleViewShowAnimation:(UIView*)incomingView :(NSString*)animType :(CGFloat)duration;
@end
