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

@interface czzAppDelegate()<czzBlacklistDownloaderDelegate, NSURLConnectionDataDelegate>

@end

@implementation czzAppDelegate
@synthesize shouldUseBackupServer;
@synthesize myhost;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    myhost = my_main_host;
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
    NSString* thumbnailFolder = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imgFolder = [thumbnailFolder stringByAppendingPathComponent:@"Images"];
    thumbnailFolder = [thumbnailFolder stringByAppendingPathComponent:@"Thumbnails"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbnailFolder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:thumbnailFolder withIntermediateDirectories:NO attributes:nil error:nil];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:imgFolder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:imgFolder withIntermediateDirectories:NO attributes:nil error:nil];
    }

    //check if the server is running and has required files
    NSURLConnection *urlConn = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[myhost stringByAppendingPathComponent:@"forums.xml"]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10] delegate:self startImmediately:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(NSString *)myhost {
    if (shouldUseBackupServer)
    {
        return my_backup_host;
    } else {
        return my_main_host;
    }
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

-(void)showToast:(NSString *)string{
    [[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] makeToast:string];
}

@end
