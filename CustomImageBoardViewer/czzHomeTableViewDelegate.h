//
//  czzThreadTableViewDelegate.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 25/05/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class czzHomeViewModelManager;
@interface czzHomeTableViewDelegate : NSObject <UITableViewDelegate>


+ (id)sharedInstance;
+(instancetype)initWithViewModelManager:(czzHomeViewModelManager*)viewModelManager;
@end
