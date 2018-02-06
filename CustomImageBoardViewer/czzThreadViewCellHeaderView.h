//
//  czzThreadViewCellHeaderView.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 2/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "CPLoadFromNibView.h"
#import "czzThread.h"

IB_DESIGNABLE
@interface czzThreadViewCellHeaderView : CPLoadFromNibView

@property (strong, nonatomic) czzThread *thread;
@property (strong, nonatomic) NSString *parentUID;
@property (strong, nonatomic) UIColor *highlightColour;
@property (strong, nonatomic) NSString *nickname;
@property (weak, nonatomic) IBOutlet UIButton *headerButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerButtonContainerViewHeightConstraint;

@end
