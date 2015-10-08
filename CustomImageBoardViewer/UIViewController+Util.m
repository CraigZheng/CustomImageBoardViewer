//
//  UIViewController+Util.m
//  CustomImageBoardViewer
//
//  Created by Craig on 27/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "UIViewController+Util.h"

@implementation UIViewController (Util)

- (BOOL)isPresented {
    return self.isViewLoaded && self.view.window;
}
@end
