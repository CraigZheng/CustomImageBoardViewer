//
//  czzSubThreadList.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 30/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzThreadList.h"

@interface czzSubThreadList : czzThreadList
@property NSString* parentID;
@property (nonatomic) czzThread *parentThread;

-(instancetype)initWithParentThread:(czzThread*)thread;
@end
