//
//  czzThreadViewCellFooterView.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 3/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "CPLoadFromNibView.h"
#import "czzThread.h"

IB_DESIGNABLE
@interface czzThreadViewCellFooterView : CPLoadFromNibView

@property (strong, nonatomic) czzThread *thread;
@property (assign, readonly) BOOL isHidden;
@end
