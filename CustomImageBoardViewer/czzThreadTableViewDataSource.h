//
//  czzThreadTableViewDataSource.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 28/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import "czzHomeTableViewDataSource.h"

@interface czzThreadTableViewDataSource : czzHomeTableViewDataSource

+(instancetype)initWithViewModelManager:(czzThreadViewManager *)viewModelManager;
@end
