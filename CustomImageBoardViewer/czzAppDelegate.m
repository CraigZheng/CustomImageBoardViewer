//
//  czzAppDelegate.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzAppDelegate.h"
#import "czzNavigationController.h"
#import "czzBlacklistDownloader.h"
#import "czzBlacklist.h"
#import "Toast+UIView.h"
#import "SMXMLDocument.h"
#import "czzSettingsCentre.h"
#import "czzCookieManager.h"
#import "czzWatchKitManager.h"
#import "czzFavouriteManagerViewController.h"
#import "czzCacheCleaner.h"
#import "czzHomeViewManager.h"
#import "czzThreadViewManager.h"
#import "czzBannerNotificationUtil.h"
#import "czzHistoryManager.h"
#import "czzFavouriteManager.h"
#import <WatchConnectivity/WatchConnectivity.h>
#import "CustomImageBoardViewer-Swift.h"

static NSString * const lastStateAppVersion = @"kLastStateAppVersion";

@interface czzAppDelegate()<czzBlacklistDownloaderDelegate, czzHomeViewManagerDelegate, WCSessionDelegate>
@property czzSettingsCentre *settingsCentre;
@property NSInteger userInterfaceStyle;
@end

@implementation czzAppDelegate
@synthesize shouldUseBackupServer;
@synthesize myhost;
@synthesize settingsCentre;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    myhost = my_main_host;
    settingsCentre = [czzSettingsCentre sharedInstance];

    // The app no longer uses a main storyboard, so the window and its root
    // navigation stack are created here.
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    czzNavigationController *rootNav = [czzNavigationController new];
    self.window.rootViewController = rootNav;
    [self.window makeKeyAndVisible];

    [self checkFolders];
    // Check cookie
    CookieManager;
        
    // The watchkit session.
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    if (@available(iOS 13.0, *)) {
        self.userInterfaceStyle = self.window.traitCollection.userInterfaceStyle;
    }
}
							
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    czzBlacklistDownloader *blacklistDownloader = [czzBlacklistDownloader new];
    blacklistDownloader.delegate = self;
    [blacklistDownloader downloadBlacklist];
    
    // Init the CacheCleaner when the app is visible to user.
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        CacheCleaner;
    }
    if (@available(iOS 13.0, *) && self.window.traitCollection.userInterfaceStyle != self.userInterfaceStyle) {
        [[czzHomeViewManager sharedManager] reloadData];
        [[NSNotificationCenter defaultCenter] postNotificationName:settingsChangedNotification
                                                            object:nil];
    }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return [czzURLHandler handleCustomURL:url];
}

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    DDLogDebug(@"%@", url.absoluteString);
    if ([url.host isEqualToString:@"acfun"]) {
        return YES;
    }
    return NO;
}

#pragma mark - WCSessionDelegate

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    __block UIBackgroundTaskIdentifier wkBackgroundTaskIdentifier;
    wkBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"backgroundTask"
                                                                              expirationHandler:^{
                                                                                  wkBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
                                                                              }];
    [[czzWatchKitManager sharedManager] handleWatchKitExtensionRequest:message
                                                                 reply:replyHandler
                                          withBackgroundTaskIdentifier:wkBackgroundTaskIdentifier];
}

#pragma mark - Break and restoration.

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
  // TODO: enable state perserving in the future.
  return NO;
//    [[NSUserDefaults standardUserDefaults] setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
//                                              forKey:lastStateAppVersion];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//    [[czzHomeViewManager sharedManager] saveCurrentState];
//    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
  // TODO: enable state restoration in the future.
  return NO;
//    BOOL shouldRestore = NO;
//    NSString *lastVersion = [[NSUserDefaults standardUserDefaults] objectForKey:lastStateAppVersion];
//    if ([[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] isEqualToString:lastVersion]) {
//        shouldRestore = YES;
//    }
//    return shouldRestore;
}

- (UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    if ([identifierComponents.lastObject isEqualToString:NSStringFromClass([UINavigationController class])]) {
        UIViewController *viewController =  [CustomAppearanceNavigationController new];
        viewController.restorationIdentifier = identifierComponents.lastObject;
        return viewController;
    }
    return nil;
}

-(NSString *)myhost {
    return [settingsCentre database_host];
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    NSError *error = nil;

    id flag = nil;
    [URL getResourceValue: &flag
                   forKey: NSURLIsExcludedFromBackupKey error: &error];
    BOOL success = [URL setResourceValue:[NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    return success;
}


-(NSString *)vendorID {
    return [UIDevice currentDevice].identifierForVendor.UUIDString;
}

#pragma mark czzBlacklistDownloader delegate
-(void)downloadSuccess:(BOOL)success result:(NSSet *)blacklistEntities{
    if (success){
        [[czzBlacklist sharedInstance] setBlacklistEntities:blacklistEntities];
    } else {
    }
}

#pragma mark - access to app delegate etc.
+ (czzAppDelegate*) sharedAppDelegate{
    return (czzAppDelegate*)[[UIApplication sharedApplication] delegate];
}

#pragma mark - folders
+(NSString *)libraryFolder {
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

+(NSString *)documentFolder {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+(NSString *)thumbnailFolder {
    return [[self libraryFolder] stringByAppendingPathComponent:@"Thumbnails"];
}

+(NSString *)imageFolder {
    return [[self libraryFolder] stringByAppendingPathComponent:@"Images"];
}

+(NSString *)threadCacheFolder {
    return [[self libraryFolder] stringByAppendingPathComponent:@"ThreadCache"];
}

+(NSString *)notificationCacheFolder {
    return [[self libraryFolder] stringByAppendingPathComponent:@"NotificationCache"];
}

-(void)showToast:(NSString *)string{
    [czzBannerNotificationUtil displayMessage:string
                                     position:BannerNotificationPositionBottom];
}

#pragma mark - show and hide uitoolbar
-(void)doSingleViewHideAnimation:(UIView*)incomingView :(NSString*)animType :(CGFloat)duration
{
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionPush];
    [animation setSubtype:animType];
    
    [animation setDuration:duration];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[incomingView layer] addAnimation:animation forKey:kCATransition];
    incomingView.hidden = YES;
}

-(void)doSingleViewShowAnimation:(UIView*)incomingView :(NSString*)animType :(CGFloat)duration
{
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionPush];
    [animation setSubtype:animType];
    
    [animation setDuration:duration];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[incomingView layer] addAnimation:animation forKey:kCATransition];
    incomingView.hidden = NO;
}

/*
 check the library directory and image folders
*/
-(void)checkFolders {
    NSArray *resourceFolders = @[[czzAppDelegate libraryFolder], [czzAppDelegate imageFolder], [czzAppDelegate thumbnailFolder], [czzAppDelegate threadCacheFolder], [czzAppDelegate notificationCacheFolder]];
    for (NSString *folderPath in resourceFolders) {
        NSError *error;
        if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath]){
            [[NSFileManager defaultManager] createDirectoryAtPath:folderPath
                                      withIntermediateDirectories:NO
                                                       attributes:[NSDictionary dictionaryWithObject:NSFileProtectionNone
                                                                                              forKey:NSFileProtectionKey]
                                                            error:&error];
            DDLogDebug(@"Create library folder: %@", folderPath);
        }
        //exclude my folders from being backed up to iCloud
        [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:folderPath]];
        [[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:NSFileProtectionNone
                                                                                  forKey:NSFileProtectionKey]
                                         ofItemAtPath:folderPath
                                                error:&error];
        if (error) {
            DDLogDebug(@"%@", error);
        }
    }
}
@end
