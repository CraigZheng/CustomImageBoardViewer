//
//  czzNavigationManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/07/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//
#define NavigationManager [czzNavigationManager sharedManager]

#import <Foundation/Foundation.h>
#import "czzNavigationController.h"

@class czzNavigationManager;
@protocol czzNavigationManagerDelegate <NSObject>
-(void)viewModelManager:(czzNavigationManager*)manager wantsToPushViewController:(UIViewController*)viewController animated:(BOOL)animated;
-(void)viewModelManager:(czzNavigationManager*)manager wantsToPopViewControllerAnimated:(BOOL)animated;
-(void)viewModelManager:(czzNavigationManager*)manager wantsToPopToViewController:(UIViewController*)viewController animated:(BOOL)animated;
-(void)viewModelManager:(czzNavigationManager*)manager wantsToSetViewController:(NSArray*)viewControllers animated:(BOOL)animated;

@end

@interface czzNavigationManager : NSObject <UINavigationControllerDelegate>
@property (weak) czzNavigationController<czzNavigationManagerDelegate> *delegate;
@property (copy) void(^pushAnimationCompletionHandler)(void);
@property (assign, nonatomic) BOOL isInTransition;

-(void)pushViewController:(UIViewController*)viewController animated:(BOOL)animated;
-(void)popViewControllerAnimated:(BOOL)animted;
-(void)popToViewController:(UIViewController*)viewController animated:(BOOL)animated;
-(void)setViewController:(NSArray*)viewControllers animated:(BOOL)animated;

+(instancetype)sharedManager;
@end
