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
#import "czzFavouriteManagerViewController.h"
#import "czzCacheCleaner.h"
#import "czzHomeViewManager.h"
#import "czzBannerNotificationUtil.h"
#import "czzHistoryManager.h"
#import "czzFavouriteManager.h"
#import <Google/Analytics.h>
#import <WatchConnectivity/WatchConnectivity.h>

#import "TalkingData.h"

//#import <BugSense-iOS/BugSenseController.h>
#import <SplunkMint/SplunkMint.h>

#define LOG_LEVEL_DEF ddLogLevel

@interface czzAppDelegate()<czzBlacklistDownloaderDelegate, czzHomeViewManagerDelegate, WCSessionDelegate>
@property czzSettingsCentre *settingsCentre;
@end

@implementation czzAppDelegate
@synthesize shouldUseBackupServer;
@synthesize myhost;
@synthesize settingsCentre;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console
    [DDLog addLogger:[DDASLLogger sharedInstance]]; // ASL = Apple System Logs
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init]; // File Logger
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:fileLogger];
    // Splunk mint configuration.
    [[Mint sharedInstance] initAndStartSessionWithAPIKey:@"cd668a8e"];
    [[Mint sharedInstance] setUserIdentifier:[UIDevice currentDevice].identifierForVendor.UUIDString];
    // Talkind data initialisation
    [TalkingData sessionStarted:@"B8168DD03CD9EF62B476CEDFBC3FB52D" withChannelId:@""];
    // Google analytic configuration
    // Configure tracker from GoogleService-Info.plist.
    NSError *configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    // Enable IDFA collection.
    [[[GAI sharedInstance] defaultTracker] setAllowIDFACollection:YES];
    
    //    // Optional: configure GAI options.
    //    GAI *gai = [GAI sharedInstance];
    //    gai.trackUncaughtExceptions = YES;  // report uncaught exceptions
    //    gai.logger.logLevel = kGAILogLevelVerbose;  // remove before app release

    myhost = my_main_host;
    settingsCentre = [czzSettingsCentre sharedInstance];
    
    [self checkFolders];
    // Check cookie
    CookieManager;
    // Check watchlist manger.
        
    // The watchkit session.
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
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
    // Init the watch list manager.
    WatchListManager;
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

#pragma mark - background fetch
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);
    __block void(^localRefCompletionHandler)(UIBackgroundFetchResult) = completionHandler;
    // Safe guard.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (localRefCompletionHandler) {
            DDLogDebug(@"Background fetch safe gurad: time limit has reached, call completionHandler with NoData as the result.");
            localRefCompletionHandler(UIBackgroundFetchResultNoData);
            localRefCompletionHandler = nil;
        }
    });
    [WatchListManager refreshWatchedThreadsWithCompletionHandler:^(NSArray *updatedThreads) {
        DDLogDebug(@"Background fetch completed.");
        UIBackgroundFetchResult backgroundFetchResult = UIBackgroundFetchResultNoData;
        
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        localNotif.fireDate = [NSDate dateWithTimeInterval:1.0 sinceDate:[NSDate new]];

        if (updatedThreads.count) {
            localNotif.alertTitle = WatchListManager.updateTitle;
            localNotif.alertBody = WatchListManager.updateContent;
            localNotif.soundName = UILocalNotificationDefaultSoundName;
            localNotif.applicationIconBadgeNumber = updatedThreads.count;

            // If the app is running in the background, schedule the notification, otherwise don't schedule it.
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
            
            backgroundFetchResult = UIBackgroundFetchResultNewData;
        }
        if (localRefCompletionHandler) {
            localRefCompletionHandler(backgroundFetchResult);
            localRefCompletionHandler = nil;
        }
    }];
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    czzFavouriteManagerViewController *favouriteManagerViewController = [czzFavouriteManagerViewController new];
    favouriteManagerViewController.launchToIndex = watchIndex; // Launch to watchlist view.
    if (self.window.rootViewController) {
        // Received local notification, most likely watch list is updated
        [NavigationManager pushViewController:favouriteManagerViewController animated:YES];
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
        if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath]){
            [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:nil];
            DDLogDebug(@"Create library folder: %@", folderPath);
        }
        //exclude my folders from being backed up to iCloud
        [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:folderPath]];
    }
}
@end
