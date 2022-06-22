//
//  UINavigationController+Util.m
//  CashByOptusPhone
//
//  Created by Craig on 16/03/2015.
//  Copyright (c) 2015 Singtel Optus Pty Ltd. All rights reserved.
//

#import "UINavigationController+Util.h"
#import "czzSettingsCentre.h"

@implementation UINavigationController (Util)

-(void)applyAppearance {
    UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [settingCentre barTintColour];
    self.navigationBar.tintColor = [settingCentre tintColour];
    self.navigationBar.standardAppearance = appearance;
    self.navigationBar.scrollEdgeAppearance = self.navigationBar.standardAppearance;
    
    //consistent look for tool bar and label
    [self.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : self.navigationBar.tintColor}];
    
    UIToolbarAppearance *toolbarAppearance = [UIToolbarAppearance new];
    [toolbarAppearance configureWithOpaqueBackground];
    toolbarAppearance.backgroundColor = [settingCentre barTintColour];
    self.toolbar.tintColor = self.navigationBar.tintColor;
    self.toolbar.standardAppearance = self.toolbar.scrollEdgeAppearance = toolbarAppearance;
}

-(void)replaceLastViewControllerWithViewController:(UIViewController *)controller animated:(BOOL)animated {
    if (!controller) {
        DLog(@"empty input view controller");
        return;
    }
    if (self.childViewControllers.count > 1) {
        NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.childViewControllers];
        [viewControllers removeLastObject];
        [viewControllers addObject:controller];
        [self setViewControllers:viewControllers animated:animated];
    } else {
        [self setViewControllers:@[controller] animated:animated];
    }
}

+(void)pushViewControllerToRoot:(UIViewController *)controller animated:(BOOL)animated {
    
}
@end
