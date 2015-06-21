//
//  ForumData.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 21/06/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ForumData : NSManagedObject

@property (nonatomic, retain) NSNumber * cooldown;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * createThreadURL;
@property (nonatomic, retain) NSNumber * forumID;
@property (nonatomic, retain) NSString * forumURL;
@property (nonatomic, retain) NSString * header;
@property (nonatomic, retain) NSString * imageHost;
@property (nonatomic, retain) NSNumber * lock;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * parserType;
@property (nonatomic, retain) NSString * threadContentURL;
@property (nonatomic, retain) NSDate * updatedAt;

@end
