//
//  UINavigationController+Util.h
//  CashByOptusPhone
//
//  Created by Craig on 16/03/2015.
//  Copyright (c) 2015 Singtel Optus Pty Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (Util)

-(void)replaceLastViewControllerWithViewController:(UIViewController*)controller animated:(BOOL)animated;
- (void)applyAppearance;

+(void)pushViewControllerToRoot:(UIViewController*)controller animated:(BOOL)animated;
@end
