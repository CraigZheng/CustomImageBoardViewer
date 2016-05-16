//
//  NSFileManager+Util.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 29/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Util)

-(NSArray<NSURL *> * _Nullable)contentsOfDirectoryAtURL:(NSURL * _Nonnull)url sortWithCreationDate:(BOOL)sort error:(NSError * _Nullable __autoreleasing * _Nullable)error;

-(long long)sizeOfFolder:(nonnull NSString *)folderPath;
@end
