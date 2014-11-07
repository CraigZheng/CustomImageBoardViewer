//
//  czzThreadCache.m
//  CustomImageBoardViewer
//
//  Created by Craig on 25/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#define THREAD_CACHE_ARCHIVE @"cacheArchive.arc"

#import "czzThreadCacheManager.h"
#import "czzThread.h"
#import "czzAppDelegate.h"
#import "czzSettingsCentre.h"
#import "czzImageCentre.h"

@interface czzThreadCacheManager()
@property NSMutableSet *existingFiles;
@property czzSettingsCentre *settingsCentre;
@end

@implementation czzThreadCacheManager
@synthesize cachePath;
@synthesize existingFiles;
@synthesize settingsCentre;

-(id)init{
    self = [super init];
    
    if (self){
        settingsCentre = [czzSettingsCentre sharedInstance];
        NSString* libraryPath = [czzAppDelegate libraryFolder];
        cachePath = [libraryPath stringByAppendingPathComponent:@"ThreadCache"];
        //if the thread cache in library directory does not exist, create it during the installation
        if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]){
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
            if (error){
                NSLog(@"error creating thread cache: %@", error);
            }
        }
        [self restoreCaches];
        if (existingFiles.count <= 0)
            [self reloadCacheFiles];
        
        if ([[czzSettingsCentre sharedInstance] autoCleanImageCache]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self clearOldFile];
            });
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveThreadCaches) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    
    return self;
}

-(void)saveThreadCaches {
    if (existingFiles.count > 0) {
        [NSKeyedArchiver archiveRootObject:existingFiles toFile:[cachePath stringByAppendingPathComponent:THREAD_CACHE_ARCHIVE]];
        NSLog(@"thread caches archived to: %@", [cachePath stringByAppendingPathComponent:THREAD_CACHE_ARCHIVE]);
    }
}

-(void)restoreCaches {
    NSDate *startDate = [NSDate new];
    //read the existing cached thread files
    @try {
        existingFiles = [NSMutableSet new];
        NSSet *tempSet = [NSKeyedUnarchiver unarchiveObjectWithFile:[cachePath stringByAppendingPathComponent:THREAD_CACHE_ARCHIVE]];
        if (tempSet.count > 0) {
            [existingFiles addObjectsFromArray:tempSet.allObjects];
            NSLog(@"archived thread cache restored");
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    NSLog(@"restoring cache took: %.1f seconds", [[NSDate new] timeIntervalSinceDate:startDate]);
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
        return [NSKeyedArchiver archiveRootObject:[NSValue valueWithCGPoint:contentOffSet] toFile:[cachePath stringByAppendingPathComponent:@"ContentOffSet.cgp"]];
    }
    @catch (NSException *exception) {
        
    }
    return NO;
}

-(CGPoint)readContentOffSetForHome {
    NSValue *contentOffSet = [NSKeyedUnarchiver unarchiveObjectWithFile:[cachePath stringByAppendingPathComponent:@"ContentOffSet.cgp"]];
    [self removeContentOffSetForHome];
    if (!contentOffSet)
        return CGPointZero;
    return contentOffSet.CGPointValue;
}

-(void)removeContentOffSetForHome {
    [[NSFileManager defaultManager] removeItemAtPath:[cachePath stringByAppendingPathComponent:@"ContentOffSet.cgp"] error:nil];
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
    //if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldCache"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"shouldCache"]) {
    if (!settingsCentre.userDefShouldCacheData) {
        return NO;
    }
    return [self saveThreads:threads WithName:[NSString stringWithFormat:@"%ld.thd", (long)parentThread.ID]];
}

-(NSArray*)readThreads:(czzThread*)parentThread{
    //user defaults settings
    //if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldCache"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"shouldCache"]) {
    if (!settingsCentre.userDefShouldCacheData) {
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
-(BOOL)saveVerticalHeights:(NSArray *)vHeighs andHorizontalHeighs:(NSArray *)hHeights ForThread:(czzThread *)parentThread {
    //if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldCache"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"shouldCache"]) {
    if (!settingsCentre.userDefShouldCacheData) {
        return NO;
    }
    @try {
        NSString *vFile = [NSString stringWithFormat:@"%ld.vht", (long)parentThread.ID];
        NSString *hFile = [NSString stringWithFormat:@"%ld.hht", (long)parentThread.ID];
        [NSKeyedArchiver archiveRootObject:vHeighs toFile:[cachePath stringByAppendingPathComponent:vFile]];
        [NSKeyedArchiver archiveRootObject:hHeights toFile:[cachePath stringByAppendingPathComponent:hFile]];
        [existingFiles addObject:vFile];
        [existingFiles addObject:hFile];
        return YES;
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    [[czzAppDelegate sharedAppDelegate] showToast:@"无法写入缓存：请检查剩余空间"];
    return NO;

}

-(NSDictionary *)readHeightsForThread:(czzThread *)parentThread {
    //if ([[NSUserDefaults standardUserDefaults] objectForKey:@"shouldCache"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"shouldCache"]) {
    if (!settingsCentre.userDefShouldCacheData) {
        return nil;
    }
    @try {
        NSString *vFile = [NSString stringWithFormat:@"%ld.vht", (long)parentThread.ID];
        NSString *hFile = [NSString stringWithFormat:@"%ld.hht", (long)parentThread.ID];
        if ([existingFiles containsObject:vFile] || [existingFiles containsObject:hFile]){
            NSArray *vHeights = [NSKeyedUnarchiver unarchiveObjectWithFile:[cachePath stringByAppendingPathComponent:vFile]];
            NSArray *hHeights = [NSKeyedUnarchiver unarchiveObjectWithFile:[cachePath stringByAppendingPathComponent:hFile]];
            NSMutableDictionary *heights = [NSMutableDictionary new];
            if (vHeights) {
                [heights setObject:vHeights forKey:@"VerticalHeights"];
            }
            if (hHeights) {
                [heights setObject:hHeights forKey:@"HorizontalHeights"];
            }
            return heights;
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
    NSArray *allCacheFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cachePath error:nil];
    NSMutableArray *files = [NSMutableArray new];
    [files addObjectsFromArray:allCacheFiles];
    existingFiles = [NSMutableSet setWithArray:files];
    

}

-(void)clearOldFile {
    if (existingFiles.count <= 0)
        return;
    NSMutableArray *newArray = [NSMutableArray new];
    NSMutableArray *existingArray = [NSMutableArray arrayWithArray:existingFiles.allObjects];
    for (NSString *f in existingArray) {
        NSString *filePath = [cachePath stringByAppendingPathComponent:f];
        if (![self isFileOlderThan10Days:filePath])
            [newArray addObject:f];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        existingFiles = [NSMutableSet setWithArray:newArray];
    });
}

-(BOOL)isFileOlderThan10Days:(NSString*)filePath {
    NSDate *today = [NSDate new];
    @try {
        NSDate *fileModifiedDate = [czzImageCentre getModificationDateForFileAtPath:filePath];
        //if older than 30 days
        if ([today timeIntervalSinceDate:fileModifiedDate] > 864000) {
            //delete this file and return YES
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            return YES;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    return NO;
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
