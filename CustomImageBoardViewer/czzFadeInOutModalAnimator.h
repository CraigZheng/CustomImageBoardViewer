//
//  czzSlideUpModalAnimator.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 13/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzFadeInOutModalAnimator : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate>
@property (assign, nonatomic) BOOL isDismissing;
@end
