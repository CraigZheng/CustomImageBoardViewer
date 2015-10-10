//
//  czzAppDelegate.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzAppDelegate.h"
#import "czzBlacklistDownloader.h"
#import "czzBlacklist.h"
#import "Toast+UIView.h"
#import "SMXMLDocument.h"
#import "czzSettingsCentre.h"
#import "czzCookieManager.h"
#import "czzWatchKitManager.h"
#import "czzWatchListManager.h"
#import "czzAppActivityManager.h"
#import "czzFavouriteManagerViewController.h"
#import "czzCacheCleaner.h"

#import <WatchConnectivity/WatchConnectivity.h>

#ifndef TARGET_IPHONE_SIMULATOR
#import "TalkingData.h"
#endif
//#import <BugSense-iOS/BugSenseController.h>
#import <SplunkMint-iOS/SplunkMint-iOS.h>

@interface czzAppDelegate()<czzBlacklistDownloaderDelegate, czzHomeViewModelManagerDelegate, WCSessionDelegate>
@property czzSettingsCentre *settingsCentre;
@end

@implementation czzAppDelegate
@synthesize shouldUseBackupServer;
@synthesize myhost;
@synthesize settingsCentre;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifndef TARGET_IPHONE_SIMULATOR
    [[Mint sharedInstance] initAndStartSession:@"cd668a8e"];
    [[Mint sharedInstance] setUserIdentifier:[UIDevice currentDevice].identifierForVendor.UUIDString];
    
    // Talkind data initialisation
    [TalkingData sessionStarted:@"B8168DD03CD9EF62B476CEDFBC3FB52D" withChannelId:@""];
#endif
    myhost = my_main_host;
    settingsCentre = [czzSettingsCentre sharedInstance];
    
    
    [self checkFolders];
    // Check cookie
    CookieManager;
    // Prepare to launch
    AppActivityManager;

    // Background fetch interval
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    return YES;
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
}


-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    DLog(@"%@", url.absoluteString);
    if ([url.host isEqualToString:@"acfun"]) {
        return YES;
    }
    return NO;
}

#pragma mark - Watch kit extension

- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply {
    __block UIBackgroundTaskIdentifier wkBackgroundTaskIdentifier;
    wkBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"backgroundTask"
                                                                              expirationHandler:^{
                                                                                  wkBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
                                                                              }];

    [[czzWatchKitManager sharedManager] handleWatchKitExtensionRequest:userInfo reply:reply withBackgroundTaskIdentifier:wkBackgroundTaskIdentifier];
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message {
    DLog(@"%s: %@", __PRETTY_FUNCTION__, message);
}

#pragma mark - background fetch
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[czzWatchListManager sharedManager] refreshWatchedThreads:^(NSArray *updatedThreads) {
        UIBackgroundFetchResult backgroundFetchResult = UIBackgroundFetchResultNoData;
        
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        localNotif.fireDate = [NSDate dateWithTimeInterval:1.0 sinceDate:[NSDate new]];

        if (updatedThreads.count) {
            localNotif.alertTitle = [NSString stringWithFormat:@"%ld thread(s) updated", (long)updatedThreads.count];
            localNotif.alertBody = [NSString stringWithFormat:@"%@", [(czzThread*)updatedThreads.firstObject content].string];
            localNotif.soundName = UILocalNotificationDefaultSoundName;
            localNotif.applicationIconBadgeNumber = updatedThreads.count;

            // If the app is running in the background, schedule the notification, otherwise don't schedule it.
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
            
            backgroundFetchResult = UIBackgroundFetchResultNewData;
        }
        completionHandler(backgroundFetchResult);
    }];
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if (self.window.rootViewController) {
        // Received local notification, most likely watch list is updated
        czzFavouriteManagerViewController *favouriteManagerViewController = [czzFavouriteManagerViewController new];
        [NavigationManager pushViewController:favouriteManagerViewController animated:YES];
    } else {
        [czzAppActivityManager sharedManager].appLaunchCompletionHandler = ^{
            czzFavouriteManagerViewController *favouriteManagerViewController = [czzFavouriteManagerViewController new];
            [NavigationManager pushViewController:favouriteManagerViewController animated:YES];
        };
    }
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


#pragma mark access to app delegate etc.
+ (czzAppDelegate*) sharedAppDelegate{
    return (czzAppDelegate*)[[UIApplication sharedApplication] delegate];
}

#pragma mark - folders
+(NSString *)libraryFolder {
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
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
    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:string];
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
        if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath]){
            [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        //exclude my folders from being backed up to iCloud
        [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:folderPath]];
    }
}
@end
