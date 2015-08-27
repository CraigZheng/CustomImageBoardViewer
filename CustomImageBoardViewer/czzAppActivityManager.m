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

@implementation czzAppActivityManager

-(instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching) name:UIApplicationDidFinishLaunchingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

-(void)applicationDidFinishLaunching {
    [self launchApp];
}

-(void)applicationDidBecomeActive {
    [self launchApp];
}

-(void)applicationDidEnterBackground {
    NSArray *viewControllers = NavigationManager.delegate.viewControllers;
    for (UIViewController* viewController in viewControllers) {
        if ([viewController respondsToSelector:@selector(saveCurrentState)]) {
            id result = [viewController performSelector:@selector(saveCurrentState)];
            DLog(@"%@: %@", NSStringFromClass(viewController.class), result);
        }
    }
    
    // Save settings
    [settingCentre saveSettings];
}

-(void)launchApp {
    UIViewController *rootViewController = AppDelegate.window.rootViewController;
    if (!rootViewController) {
        [[czzHomeViewModelManager sharedManager] restorePreviousState]; 
        
        rootViewController = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateInitialViewController];
        if (!AppDelegate.window)
            AppDelegate.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        AppDelegate.window.rootViewController = rootViewController;
        [AppDelegate.window makeKeyAndVisible];
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
