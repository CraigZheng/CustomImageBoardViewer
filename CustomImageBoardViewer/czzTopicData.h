//
//  czzTopicData.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 28/06/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface czzTopicData : NSManagedObject

@property (nonatomic, retain) NSNumber * threadID;
@property (nonatomic, retain) NSString * replies;

@end
