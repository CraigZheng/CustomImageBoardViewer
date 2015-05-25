//
//  czzThreadTableViewDataSource.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class czzThreadList;
@interface czzThreadTableViewDataSource : NSObject <UITableViewDataSource, UITableViewDelegate>

@property czzThreadList *threadList;

+(instancetype)initWithThreadList:(czzThreadList*)threadList;
@end
