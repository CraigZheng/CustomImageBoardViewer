//
//  czzThreadViewCellHeaderView.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 2/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "CPLoadFromNibView.h"
#import "czzThread.h"

@interface czzThreadViewCellHeaderView : CPLoadFromNibView

@property (strong, nonatomic) czzThread *myThread;
@property (strong, nonatomic) NSString *parentUID;
@property (assign, nonatomic) BOOL shouldHighLight;

@end
