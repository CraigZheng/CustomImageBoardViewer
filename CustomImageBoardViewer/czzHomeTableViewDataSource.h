//
//  czzThreadTableViewDataSource.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "czzMenuEnabledTableViewCell.h"

@class czzHomeViewModelManager;
@interface czzHomeTableViewDataSource : NSObject <UITableViewDataSource, UITableViewDelegate, czzMenuEnabledTableViewCellProtocol>
@property czzHomeViewModelManager *viewModelManager;
@property (weak, nonatomic) UITableView *myTableView;

+(instancetype)initWithViewModelManager:(czzHomeViewModelManager*)viewModelManager;
@end
