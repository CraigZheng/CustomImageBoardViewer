//
//  czzNavigationViewModelManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/07/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//
#define NavigationManager [czzNavigationViewModelManager sharedManager]

#import <Foundation/Foundation.h>
#import "czzNavigationController.h"

@class czzNavigationViewModelManager;
@protocol czzNavigationViewModelManagerDelegate <NSObject>
-(void)viewModelManager:(czzNavigationViewModelManager*)manager wantsToPushViewController:(UIViewController*)viewController animated:(BOOL)animated;
-(void)viewModelManager:(czzNavigationViewModelManager*)manager wantsToPopViewControllerAnimated:(BOOL)animated;
-(void)viewModelManager:(czzNavigationViewModelManager*)manager wantsToPopToViewController:(UIViewController*)viewController animated:(BOOL)animated;

@end

@interface czzNavigationViewModelManager : NSObject <UINavigationControllerDelegate>
@property (weak) czzNavigationController<czzNavigationViewModelManagerDelegate> *delegate;
@property (copy) void(^pushAnimationCompletionHandler)(void);
@property (assign, nonatomic) BOOL isInTransition;

-(void)pushViewController:(UIViewController*)viewController animated:(BOOL)animated;
-(void)popViewControllerAnimated:(BOOL)animted;
-(void)popToViewController:(UIViewController*)viewController animated:(BOOL)animated;

+(instancetype)sharedManager;
@end
