//
//  czzCacheCleaner.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#define CacheCleaner [czzCacheCleaner sharedInstance]

#import <Foundation/Foundation.h>

@interface czzCacheCleaner : NSObject
@property (strong, nonatomic) NSDate *dateOfLastCheck;
@property (strong, nonatomic) NSDate *dateOfLastClean;

- (NSArray<NSURL *> *)expiredFilesInFolder:(NSString *)folderPath;
- (void)cleanExpiredFiles:(NSArray<NSURL *> *)expiredFiles;

+ (instancetype)sharedInstance;
@end
