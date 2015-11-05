//
//  czzAppActivityManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzAppActivityManager.h"
#import "czzSettingsCentre.h"
#import "czzHomeViewManager.h"
#import "czzThreadViewManager.h"
#import "czzNavigationManager.h"
#import "czzHomeViewController.h"
#import "czzThreadViewController.h"

NSString * const APP_STATE_CACHE_FILE = @"APP_STATE_CACHE_FILE.dat";

@interface czzAppActivityManager () <NSCoding>
@property (nonatomic, strong) czzHomeViewManager *homeViewManager;
@property (nonatomic, strong) czzThreadViewManager *threadViewManager;
@property (nonatomic, readonly) NSString *cacheFilePath;
@end

@implementation czzAppActivityManager

-(instancetype)init {
    self = [super init];
    if (self) {
        [self restoreState];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching) name:UIApplicationDidFinishLaunchingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        // Try to restore from cache file.
    }
    return self;
}

#pragma mark - state perserving and restoring
- (NSString*)saveCurrentState {
    if ([NSKeyedArchiver archiveRootObject:self toFile:self.cacheFilePath]) {
        DLog(@"%@ successfully saved state", NSStringFromClass(self.class));
    } else {
        DLog(@"state cannot be saved for %@", NSStringFromClass(self.class));
    }
    return self.cacheFilePath;
}

- (void)restoreState {
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.cacheFilePath]) {
        DLog(@"%@ cache state file exists, trying to recover...", NSStringFromClass(self.class));
        @try {
            NSData *cacheFileContent = [NSData dataWithContentsOfFile:self.cacheFilePath];
            // Delete cache file immediately.
//#ifndef DEBUG
            [[NSFileManager defaultManager] removeItemAtPath:self.cacheFilePath error:nil];
//#endif
            czzAppActivityManager *tempAppActivityManager = [NSKeyedUnarchiver unarchiveObjectWithData:cacheFileContent];
            if (tempAppActivityManager) {
                self.homeViewManager = tempAppActivityManager.homeViewManager;
                self.threadViewManager = tempAppActivityManager.threadViewManager;
                
                DLog(@"%@ successfully recovered from %@", NSStringFromClass(self.class), self.cacheFilePath);
            }
        }
        @catch (NSException *exception) {
            DLog(@"%@", exception);
        }
    }
}

#pragma mark - Application life cycle
-(void)applicationDidFinishLaunching {
    [self launchApp];
}

-(void)applicationDidBecomeActive {
    [self launchApp];
}

-(void)applicationDidEnterBackground {
    NSArray *viewControllers = NavigationManager.delegate.viewControllers;
    for (UIViewController* viewController in viewControllers) {
        // Tell view controllers to save their current states.
        if ([viewController respondsToSelector:@selector(saveCurrentState)]) {
            [viewController performSelector:@selector(saveCurrentState)];
        }
        // Retrive the viewManager objects
        czzHomeViewManager *viewManager;
        if ([viewController respondsToSelector:@selector(homeViewManager)]) {
            viewManager = [viewController performSelector:@selector(homeViewManager)];
        } else if ([viewController respondsToSelector:@selector(threadViewManager)]) {
            viewManager = [viewController performSelector:@selector(threadViewManager)];
        }
        
        if ([viewManager isMemberOfClass:[czzHomeViewManager class]]) {
            self.homeViewManager = viewManager;
        } else if ([viewManager isMemberOfClass:[czzThreadViewManager class]]) {
            self.threadViewManager = (czzThreadViewManager*)viewManager;
        }

    }
    
    // Save self.
    [self saveCurrentState];
    // Save settings
    [settingCentre saveSettings];
}

-(void)launchApp {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        return;
    }
    UIViewController *rootViewController = AppDelegate.window.rootViewController;
    if (!rootViewController) {
        
        rootViewController = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateInitialViewController];
        if (!AppDelegate.window)
            AppDelegate.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        AppDelegate.window.rootViewController = rootViewController;
        [AppDelegate.window makeKeyAndVisible];
        
        if (self.homeViewManager) {
            // The app is being launched, set the singleton for czzHomeViewManager
            [czzHomeViewManager setSharedManager:self.homeViewManager];
            
            NSMutableArray *restoredViewControllers = [NSMutableArray new];
            czzThreadViewController *threadViewController;
            czzHomeViewController *homeViewController = [czzHomeViewController new];
            self.homeViewManager.delegate = homeViewController;
            [restoredViewControllers addObject:homeViewController];
            if (self.threadViewManager) {
                threadViewController = [czzThreadViewController new];
                threadViewController.threadViewManager = self.threadViewManager;
                self.threadViewManager.delegate = threadViewController;
                // Set alpha to 0, to avoid thread tableview giving a jumpping appearance...
                threadViewController.threadTableView.alpha = 0;
                [restoredViewControllers addObject:threadViewController];
            }
            [NavigationManager setViewController:restoredViewControllers animated:NO];
            [[NSOperationQueue currentQueue] addOperationWithBlock:^{
                if (threadViewController.threadViewManager) {
                    // Restore the content offset for thread view controller.
                    [threadViewController.threadViewManager scrollToContentOffset:threadViewController.threadViewManager.currentOffSet];
                }
                threadViewController.threadTableView.alpha = 1;
            }];
        }
    }
    // Clear any left over
    self.homeViewManager = self.threadViewManager = nil;
    
    if (self.appLaunchCompletionHandler) {
        self.appLaunchCompletionHandler();
        self.appLaunchCompletionHandler = nil;
    }
}

#pragma mark - Getters
- (NSString *)cacheFilePath {
    return [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:APP_STATE_CACHE_FILE];
}

#pragma mark - NSCoding
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    self.homeViewManager = [aDecoder decodeObjectForKey:@"homeViewManager"];
    self.threadViewManager = [aDecoder decodeObjectForKey:@"threadViewManager"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (self.homeViewManager) {
        [aCoder encodeObject:self.homeViewManager forKey:@"homeViewManager"];
    }
    if (self.threadViewManager) {
        [aCoder encodeObject:self.threadViewManager forKey:@"threadViewManager"];
    }
}

+ (instancetype)sharedManager
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

@end
