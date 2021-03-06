//
//  czzCacheCleaner.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/10/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzCacheCleaner.h"

#import "NSFileManager+Util.h"
#import "MBProgressHUD.h"
#import "czzAppDelegate.h"
#import "czzSettingsCentre.h"

@interface czzCacheCleaner () <UIAlertViewDelegate>
@property (strong, nonatomic) NSMutableArray *toBeDeletedFileURLs;
@property (strong, nonatomic) UIAlertView *confirmCleanAlertView;
@property (strong, nonatomic) NSDate *dateOfLastClean;
@end

@implementation czzCacheCleaner

-(instancetype)init {
    self = [super init];
    if (self) {
        if (settingCentre.userDefShouldCleanCaches) {
            self.dateOfLastClean = [[NSUserDefaults standardUserDefaults] objectForKey:[czzCacheCleaner kDateOfLastClean]];
            [self checkAndClean];
        }
    }
    return self;
}

-(void)checkAndClean {
    NSArray *cacheFolders = @[[czzAppDelegate imageFolder], [czzAppDelegate thumbnailFolder], [czzAppDelegate threadCacheFolder]];

    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.month = -1; // 1 month eariler.

    NSDate *aMonthAgo = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] dateByAddingComponents:components toDate:[NSDate new] options:0];
    
    // 1 month has passed since last time I cleaned.
    if (!self.dateOfLastClean || [self.dateOfLastClean compare:aMonthAgo] == NSOrderedAscending) {
        NSDateFormatter *debugDateFormatter = [NSDateFormatter new];
        debugDateFormatter.dateFormat = @"yyyy-MM-dd";
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            self.toBeDeletedFileURLs = [NSMutableArray new];
            for (NSString *folderPath in cacheFolders) {
                for (NSURL *fileURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:folderPath] includingPropertiesForKeys:@[NSURLContentModificationDateKey] options:0 error:nil]) {
                    NSDate *fileCreationDate;
                    [fileURL getResourceValue:&fileCreationDate forKey:NSURLContentModificationDateKey error:nil];
                    if ([fileCreationDate compare:aMonthAgo] == NSOrderedAscending) {
                        [self.toBeDeletedFileURLs addObject:fileURL];
                    }
                }
            }
            // Notify user in the main thread.
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.toBeDeletedFileURLs.count) {
                    self.confirmCleanAlertView = [[UIAlertView alloc] initWithTitle:@"每月自动清理缓存"
                                                                            message:[NSString stringWithFormat:@"%lu个文件已经相当老，是否删除？", self.toBeDeletedFileURLs.count]
                                                                           delegate:self
                                                                  cancelButtonTitle:@"否"
                                                                  otherButtonTitles:@"删除", nil];
                    [self.confirmCleanAlertView show];
                }
            });
        });
    }
   
}

-(void)cleanCompleted {
    self.dateOfLastClean = [NSDate new];
    if (self.toBeDeletedFileURLs.count) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:[NSString stringWithFormat:@"删除了%lu个文件", (long)self.toBeDeletedFileURLs.count]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: nil] show];
    }
    self.toBeDeletedFileURLs = [NSMutableArray new];
    [[NSUserDefaults standardUserDefaults] setObject:self.dateOfLastClean
                                              forKey:[czzCacheCleaner kDateOfLastClean]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (self.confirmCleanAlertView == alertView) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"下次自动检查将会在一个月之后，你也可以在设置中关闭自动检查，或者手动清空缓存。"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            [self cleanCompleted];
        } else {
            MBProgressHUD *progressHub = [MBProgressHUD showHUDAddedTo:NavigationManager.delegate.view animated:YES];
            __block NSInteger deletedFileCount = 0;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                for (NSURL *fileURL in self.toBeDeletedFileURLs) {
                    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
                    deletedFileCount ++;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progressHub.progress = deletedFileCount / self.toBeDeletedFileURLs.count;
                        progressHub.labelText = [NSString stringWithFormat:@"%lu/%lu files deleted...", deletedFileCount, (long)self.toBeDeletedFileURLs.count];
                        if (deletedFileCount >= self.toBeDeletedFileURLs.count) {
                            [progressHub hide:YES];
                            [self cleanCompleted];
                            return;
                        }
                    });
                }
            });
        }
    }
}

+(NSString*)kDateOfLastClean {
    return @"kDateOfLastClean";
}

+(instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}
@end
