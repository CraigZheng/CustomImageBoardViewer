//
//  UINavigationController+Util.m
//  CashByOptusPhone
//
//  Created by Craig on 16/03/2015.
//  Copyright (c) 2015 Singtel Optus Pty Ltd. All rights reserved.
//

#import "UINavigationController+Util.h"

@implementation UINavigationController (Util)

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
