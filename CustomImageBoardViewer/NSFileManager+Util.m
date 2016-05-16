//
//  NSFileManager+Util.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 29/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "NSFileManager+Util.h"

@implementation NSFileManager (Util)
-(NSArray<NSURL *> *)contentsOfDirectoryAtURL:(NSURL *)url sortWithCreationDate:(BOOL)sort error:(NSError * _Nullable __autoreleasing *)error {
    NSArray *results = [self contentsOfDirectoryAtURL:url includingPropertiesForKeys:sort ? @[NSURLContentModificationDateKey] : nil options:0 error:error];
    
    if (sort) {
        results = [results sortedArrayUsingComparator:^NSComparisonResult(NSURL*  _Nonnull obj1, NSURL*  _Nonnull obj2) {
            NSDate *creationDate1, *creationDate2;
            
            [obj1 getResourceValue:&creationDate1 forKey:NSURLContentModificationDateKey error:nil];
            [obj2 getResourceValue:&creationDate2 forKey:NSURLContentModificationDateKey error:nil];
            
            return [creationDate2 compare:creationDate1];
        }];
    }
    return results;
}

-(long long)sizeOfFolder:(NSString *)folderPath
{
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
    
    NSString *file;
    unsigned long long int folderSize = 0;
    
    while (file = [contentsEnumurator nextObject]) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:file] error:nil];
        folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
    }
    
    return folderSize;
}
@end
