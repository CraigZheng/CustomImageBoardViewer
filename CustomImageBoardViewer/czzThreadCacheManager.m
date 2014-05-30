//
//  czzThreadCache.m
//  CustomImageBoardViewer
//
//  Created by Craig on 25/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzThreadCacheManager.h"
#import "czzThread.h"
#import "czzAppDelegate.h"

@interface czzThreadCacheManager()
@property NSMutableSet *existingFiles;
@end

@implementation czzThreadCacheManager
@synthesize cachePath;
@synthesize existingFiles;

-(id)init{
    self = [super init];
    
    if (self){
        NSString* libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        cachePath = [libraryPath stringByAppendingPathComponent:@"ThreadCache"];
        //if the thread cache in library directory does not exist, create it during the installation
        if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]){
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
            if (error){
                NSLog(@"error creating thread cache: %@", error);
            }
        }
        //read the existing cached thread files
        [self reloadCacheFiles];
    }
    
    return self;
}

+ (id)sharedInstance
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}


#pragma mark - HomeViewController
-(BOOL)saveContentOffSetForHome:(CGPoint)contentOffSet {
    @try {
        return [NSKeyedArchiver archiveRootObject:[NSValue valueWithCGPoint:contentOffSet] toFile:[cachePath stringByAppendingPathComponent:@"ContentOffSet"]];
    }
    @catch (NSException *exception) {
        
    }
    return NO;
}

-(CGPoint)readContentOffSetForHome {
    NSValue *contentOffSet = [NSKeyedUnarchiver unarchiveObjectWithFile:[cachePath stringByAppendingPathComponent:@"ContentOffSet"]];
    [self removeContentOffSetForHome];
    if (!contentOffSet)
        return CGPointZero;
    return contentOffSet.CGPointValue;
}

-(void)removeContentOffSetForHome {
    [[NSFileManager defaultManager] removeItemAtPath:[cachePath stringByAppendingPathComponent:@"ContentOffSet"] error:nil];
}

-(BOOL)saveSelectedThreadForHome:(czzThread *)selectedThread {
    return [self saveThreads:@[selectedThread] WithName:@"SelectedThread.thd"];
}

-(czzThread*)readSelectedThreadForHome {
    NSArray *selectedThread = [NSArray arrayWithArray:[self readThreadsFromFileName:@"SelectedThread.thd"]];
    if (selectedThread.count > 0) {

        return selectedThread.firstObject;
    }
    return nil;
}

-(void)removeSelectedThreadForHome {
    [self removeThreadWithName:@"SelectedThread.thd"];
}

-(BOOL)saveThreadsForHome:(NSArray *)threads {
    return [self saveThreads:threads WithName:[NSString stringWithFormat:@"%@.thd", @"Home"]];
}

-(NSArray *)readThreadsForHome {
    NSArray *threadsForHome = [self readThreadsFromFileName:@"Home.thd"];
    [self removeThreadsForHome];
    return threadsForHome;
}

-(void)removeThreadsForHome {
    NSString *fileName = [NSString stringWithFormat:@"%@.thd", @"Home"];
    [[NSFileManager defaultManager] removeItemAtPath:[cachePath stringByAppendingPathComponent:fileName] error:nil];

}

#pragma mark - ThreadViewController
-(BOOL)saveThreads:(NSArray *)threads forThread:(czzThread *)parentThread{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldCache"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"shouldCache"]) {
        return NO;
    }
    return [self saveThreads:threads WithName:[NSString stringWithFormat:@"%ld.thd", (long)parentThread.ID]];
}

-(NSArray*)readThreads:(czzThread*)parentThread{
    //user defaults settings
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldCache"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"shouldCache"]) {
        return nil;
    }
    @try {
        NSString *fileName = [NSString stringWithFormat:@"%ld.thd", (long)parentThread.ID];
        return [self readThreadsFromFileName:fileName];
    }
    @catch (NSException *exception) {
        
    }
}

#pragma mark - heights
-(BOOL)saveHeights:(NSArray*)heights ForThread:(czzThread *)parentThread {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldCache"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"shouldCache"]) {
        return NO;
    }
    @try {
        NSString *fileName = [NSString stringWithFormat:@"%ld.hgt", (long)parentThread.ID];
        [NSKeyedArchiver archiveRootObject:heights toFile:[cachePath stringByAppendingPathComponent:fileName]];
        [existingFiles addObject:fileName];
        return YES;
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    [[czzAppDelegate sharedAppDelegate] showToast:@"无法写入缓存：请检查剩余空间"];
    return NO;
}

-(NSArray *)readHeightsForThread:(czzThread *)parentThread {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldCache"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"shouldCache"]) {
        return nil;
    }
    @try {
        NSString *fileName = [NSString stringWithFormat:@"%ld.hgt", (long)parentThread.ID];
        if ([existingFiles containsObject:fileName]){
            //            return [NSMutableSet setWithArray:
            //                    [NSKeyedUnarchiver unarchiveObjectWithFile:[cachePath stringByAppendingPathComponent:fileName]]];
            return [NSKeyedUnarchiver unarchiveObjectWithFile:[cachePath stringByAppendingPathComponent:fileName]];
            //
        }
    }
    @catch (NSException *exception) {
        
    }
    return nil;
}


#pragma mark - Read threads
-(NSArray*)readThreadsFromFileName:(NSString*)name {
    if ([existingFiles containsObject:name]){
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithFile:[cachePath stringByAppendingPathComponent:name]];
        return array;
        //
    }
    return nil;

}

#pragma mark - Write threads
-(BOOL)saveThreads:(NSArray*)threads WithName:(NSString*)name {
    @try {
        [NSKeyedArchiver archiveRootObject:threads toFile:[cachePath stringByAppendingPathComponent:name]];
        [existingFiles addObject:name];
        return YES;
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    [[czzAppDelegate sharedAppDelegate] showToast:@"无法写入缓存：请检查剩余空间"];
    return NO;
}


#pragma mark - delete
-(void)removeThreadCache:(czzThread *)thread{
    NSString *fileName = [NSString stringWithFormat:@"%ld.thd", (long)thread.ID];
    NSString *heightFile = [NSString stringWithFormat:@"%ld.hgt", (long)thread.ID];

    [self removeThreadWithName:fileName];
    [self removeThreadWithName:heightFile];
    [self reloadCacheFiles];
}

-(void)removeThreadWithName:(NSString*)fileName {
    [[NSFileManager defaultManager] removeItemAtPath:[cachePath stringByAppendingPathComponent:fileName] error:nil];
}

-(void)removeAllThreadCache{
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cachePath error:nil];
    for (NSString *file in files) {
        [[NSFileManager defaultManager] removeItemAtPath:[cachePath stringByAppendingPathComponent:file] error:nil];
    }
    [self reloadCacheFiles];
}

-(void)reloadCacheFiles{
    existingFiles = [NSMutableSet setWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:cachePath error:nil]];

}

-(NSString *)totalSize{
    return [self sizeOfFolder:cachePath];
}

-(NSString *)sizeOfFolder:(NSString *)folderPath
{
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
    
    NSString *file;
    unsigned long long int folderSize = 0;
    
    while (file = [contentsEnumurator nextObject]) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:file] error:nil];
        folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
    }
    
    //This line will give you formatted size from bytes ....
    NSString *folderSizeStr = [NSByteCountFormatter stringFromByteCount:folderSize countStyle:NSByteCountFormatterCountStyleFile];
    return folderSizeStr;
}
@end
