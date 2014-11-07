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
#import "czzForum.h"
#import "czzSettingsCentre.h"

#import <BugSense-iOS/BugSenseController.h>

//Dart integration
#import "DartCrowdSourcingLib/DartCrowdSourcingLib.h"

@interface czzAppDelegate()<czzBlacklistDownloaderDelegate, NSURLConnectionDataDelegate>
@property czzSettingsCentre *settingsCentre;
@end

@implementation czzAppDelegate
@synthesize shouldUseBackupServer;
@synthesize myhost;
@synthesize homeViewController;
@synthesize settingsCentre;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [BugSenseController sharedControllerWithBugSenseAPIKey:@"cd668a8e"];
    [BugSenseController setUserIdentifier:[UIDevice currentDevice].identifierForVendor.UUIDString];
    myhost = my_main_host;
    settingsCentre = [czzSettingsCentre sharedInstance];
    [settingsCentre downloadSettings];
    
    //Dart integration
    if (settingsCentre.shouldAllowDart) {
        [DartCrowdSourcingLib setEnableGPS:NO];
        [DartCrowdSourcingLib setEnableBackgroundGPS:NO];
        [DartCrowdSourcingLib initWithApiKey:@"CustomImageBoardViewer" version:@"0.5" homeMccMnc:@"50502" testerID:@"CustomImageBoardViewer" uploadURL:nil];
    } else {
        [DartCrowdSourcingLib disableCollection];
    }
#ifdef DEBUG
    [DartCrowdSourcingLib enableCollection]; //enable collection for debug build only
#endif
    
//    [DartCrowdSourcingLib initWithApiKey:@"CustomImageBoardViewer" version:@"0.1" homeMccMnc:@"50502" testerID:@"CustomImageBoardViewer@optus.com" uploadURL:nil];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if (homeViewController && homeViewController.threads.count > 0) {
        [homeViewController prepareToEnterBackground];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    czzBlacklistDownloader *blacklistDownloader = [czzBlacklistDownloader new];
    blacklistDownloader.delegate = self;
    [blacklistDownloader downloadBlacklist];
    //check the library directory and image folders
    NSString* libraryFolder = [czzAppDelegate libraryFolder];
    NSString *imgFolder = [libraryFolder stringByAppendingPathComponent:@"Images"];
    NSString *thumbnailFolder = [libraryFolder stringByAppendingPathComponent:@"Thumbnails"];
    NSString *notificationCacheFolder = [libraryFolder stringByAppendingPathComponent:@"NotificationCache"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbnailFolder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:thumbnailFolder withIntermediateDirectories:NO attributes:nil error:nil];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:imgFolder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:imgFolder withIntermediateDirectories:NO attributes:nil error:nil];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:notificationCacheFolder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:notificationCacheFolder withIntermediateDirectories:NO attributes:nil error:nil];
    }
    //exclude my folders from being backed up to iCloud
    [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:imgFolder]];
    [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:thumbnailFolder]];
    [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:notificationCacheFolder]];
    //restore homeview controller
    if (homeViewController) {
        [homeViewController restoreFromBackground];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - background fetch
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    //dart intergration
    [DartCrowdSourcingLib performBackgroundLoggingWithCompletionHandler:nil andResult:UIBackgroundFetchResultNoData];
    completionHandler(UIBackgroundFetchResultNoData);
}

-(NSString *)myhost {
    if (shouldUseBackupServer)
    {
        return my_backup_host;
    } else {
        return my_main_host;
    }
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    NSError *error = nil;

    id flag = nil;
    [URL getResourceValue: &flag
                   forKey: NSURLIsExcludedFromBackupKey error: &error];
    NSLog (@"NSURLIsExcludedFromBackupKey flag value is %@", flag);

    BOOL success = [URL setResourceValue:[NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    
    return success;
}


-(NSString *)vendorID {
    return [UIDevice currentDevice].identifierForVendor.UUIDString;
}

#pragma mark - NSURLConnectionDelegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    shouldUseBackupServer = YES;
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([((NSHTTPURLResponse *)response) statusCode] == 404) {
        shouldUseBackupServer = YES;
    } else {
        shouldUseBackupServer = NO;
    }
    [connection cancel];
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

#pragma mark - library folder
+(NSString *)libraryFolder {
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
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

#pragma mark - forumName
-(NSString *)getForumIDFromForumName:(NSString *)fName {
    for (czzForum *forum in self.forums) {
        if ([forum.name isEqualToString:fName]) {
            return [NSString stringWithFormat:@"%ld", (long)forum.forumID];
        }
    }
    return @"0";
}

@end
