//
//  czzAppActivityManager.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzAppActivityManager.h"
#import "czzSettingsCentre.h"
#import "czzHomeViewModelManager.h"
#import "czzThreadViewModelManager.h"
#import "czzNavigationViewModelManager.h"
#import "czzHomeViewController.h"
#import "czzThreadViewController.h"

NSString * const APP_STATE_CACHE_FILE = @"APP_STATE_CACHE_FILE.dat";

@interface czzAppActivityManager () <NSCoding>
@property (nonatomic, strong) czzHomeViewModelManager *homeViewModelManager;
@property (nonatomic, strong) czzThreadViewModelManager *threadViewModelManager;
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
                self.homeViewModelManager = tempAppActivityManager.homeViewModelManager;
                self.threadViewModelManager = tempAppActivityManager.threadViewModelManager;
                
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
        // Retrive the viewModelManager objects
        if ([viewController respondsToSelector:@selector(viewModelManager)]) {
            czzHomeViewModelManager *viewModelManager = [viewController performSelector:@selector(viewModelManager)];
            if ([viewModelManager isMemberOfClass:[czzHomeViewModelManager class]]) {
                self.homeViewModelManager = viewModelManager;
            } else if ([viewModelManager isMemberOfClass:[czzThreadViewModelManager class]]) {
                self.threadViewModelManager = (czzThreadViewModelManager*)viewModelManager;
            }
        }
    }
    
    // Save self.
    [self saveCurrentState];
    // Save settings
    [settingCentre saveSettings];
}

-(void)launchApp {
    UIViewController *rootViewController = AppDelegate.window.rootViewController;
    if (!rootViewController) {
        
        rootViewController = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateInitialViewController];
        if (!AppDelegate.window)
            AppDelegate.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        AppDelegate.window.rootViewController = rootViewController;
        [AppDelegate.window makeKeyAndVisible];
        
        if (self.homeViewModelManager) {
            NSMutableArray *restoredViewControllers = [NSMutableArray new];
            czzThreadViewController *threadViewController;
            czzHomeViewController *homeViewController = [czzHomeViewController new];
            homeViewController.viewModelManager = self.homeViewModelManager;
            self.homeViewModelManager.delegate = homeViewController;
            [restoredViewControllers addObject:homeViewController];
            if (self.threadViewModelManager) {
                threadViewController = [czzThreadViewController new];
                threadViewController.viewModelManager = self.threadViewModelManager;
                self.threadViewModelManager.delegate = threadViewController;
                // Set alpha to 0, to avoid thread tableview giving a jumpping appearance...
                threadViewController.view.alpha = 0;
                [restoredViewControllers addObject:threadViewController];
            }
            [NavigationManager setViewController:restoredViewControllers animated:NO];
            [[NSOperationQueue currentQueue] addOperationWithBlock:^{
                if (threadViewController.viewModelManager) {
                    // Restore the content offset for thread view controller.
                    [threadViewController.viewModelManager scrollToContentOffset:threadViewController.viewModelManager.currentOffSet];
                }
                threadViewController.view.alpha = 1;
            }];
        }
    }
    // Clear any left over
    self.homeViewModelManager = self.threadViewModelManager = nil;
}

#pragma mark - Getters
- (NSString *)cacheFilePath {
    return [[czzAppDelegate libraryFolder] stringByAppendingPathComponent:APP_STATE_CACHE_FILE];
}

#pragma mark - NSCoding
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    self.homeViewModelManager = [aDecoder decodeObjectForKey:@"homeViewModelManager"];
    self.threadViewModelManager = [aDecoder decodeObjectForKey:@"threadViewModelManager"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (self.homeViewModelManager) {
        [aCoder encodeObject:self.homeViewModelManager forKey:@"homeViewModelManager"];
    }
    if (self.threadViewModelManager) {
        [aCoder encodeObject:self.threadViewModelManager forKey:@"threadViewModelManager"];
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