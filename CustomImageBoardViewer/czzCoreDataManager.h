//
//  czzCoreDataManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 21/06/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "czzThread.h"
#import "ThreadData.h"

#define CoreDataManager [czzCoreDataManager sharedInstance]

@interface czzCoreDataManager : NSObject
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;

-(void)insertThreadIntoContext:(czzThread*)thread;

+(id)sharedInstance;
@end
