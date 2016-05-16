//
//  GSIndeterminateProgressView.h
//  Neverlate
//
//  Created by Endika Gutiérrez Salas on 15/11/13.
//  Copyright (c) 2013 Endika Gutiérrez Salas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GSIndeterminateProgressView : UIView

@property (nonatomic, strong) UIColor   * progressTintColor;
@property (nonatomic, strong) UIColor   * trackTintColor;

/*! A Boolean value that controls whether the receiver is hidden when the animation is stopped. Default YES */
@property (nonatomic) BOOL hidesWhenStopped;
@property (nonatomic, readonly) BOOL isAnimating;

- (void)startAnimating;
- (void)stopAnimating;
-(void)showWarning;

- (BOOL)isAnimating;

- (instancetype)initWithParentView:(UIView*)parentView alignToTop:(UIView*)topView;
@end
