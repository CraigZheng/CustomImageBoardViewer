//
//  czzThreadViewCellHeaderView.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 2/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "czzThread.h"

@interface czzThreadViewCellHeaderView : UIView

@property (strong, nonatomic) czzThread *thread;
@property (strong, nonatomic) NSString *parentUID;
@property (strong, nonatomic) UIColor *highlightColour;
@property (strong, nonatomic) NSString *nickname;
@property (strong, nonatomic) UIButton *headerButton;
@property (strong, nonatomic) NSLayoutConstraint *headerButtonContainerViewHeightConstraint;

@end
