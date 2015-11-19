//
//  UIViewController+Util.h
//  CustomImageBoardViewer
//
//  Created by Craig on 27/08/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Google/Analytics.h>

@interface UIViewController (Util)
@property (nonatomic, readonly) BOOL isPresented;
-(BOOL)isModal;
@end
