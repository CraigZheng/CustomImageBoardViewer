//
//  czzThreadTableViewDelegate.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/07/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzHomeViewDelegate.h"
#import "czzThreadViewModelManager.h"

@interface czzThreadViewDelegate : czzHomeViewDelegate
@property (weak, nonatomic) czzThreadViewModelManager *viewModelManager;

+(instancetype)initWithViewModelManager:(czzThreadViewModelManager *)viewModelManager;
@end
