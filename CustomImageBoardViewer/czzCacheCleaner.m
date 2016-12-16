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

static NSString * const kDateOfLastCheck = @"kDateOfLastCheck";
static NSString * const kDateOfLastClean = @"kDateOfLastClean";

@interface czzCacheCleaner () <UIAlertViewDelegate>
@property (strong, nonatomic) NSMutableArray *toBeDeletedFileURLs;
@property (strong, nonatomic) UIAlertView *confirmCleanAlertView;

// Time references.
@property (strong, nonatomic) NSDate *aWeek;
@property (strong, nonatomic) NSDate *aMonth;
@property (strong, nonatomic) NSDate *sixMonths;
@property (strong, nonatomic) NSDate *twelveMonths;
@property (readonly, nonnull) NSDate *referenceDate;

@end

@implementation czzCacheCleaner

- (NSArray<NSURL *> *)expiredFilesInFolder:(NSString *)folderPath {
    if (settingCentre.cacheExpiry == CacheExpiryNever) {
        // Return empty array, because will never expire.
        return @[];
    }
    // Get contents from the given folder.
    NSMutableArray<NSURL *> * expiredFileURLs = [NSMutableArray new];
    for (NSURL *fileURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:folderPath]
                                                         includingPropertiesForKeys:@[NSURLContentModificationDateKey]
                                                                            options:0
                                                                              error:nil]) {
        if ([self isFileExpired:fileURL]) {
            [expiredFileURLs addObject:fileURL];
        }
    }
    return expiredFileURLs;
}

- (BOOL)isFileExpired:(NSURL *)fileURL {
    BOOL isExpired = NO;
    if (fileURL) {
        NSDate *fileModifiedDate;
        [fileURL getResourceValue:&fileModifiedDate forKey:NSURLContentModificationDateKey error:nil];
        isExpired = [fileModifiedDate compare:self.referenceDate] == NSOrderedAscending;
    }
    return isExpired;
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
    self.dateOfLastClean = [NSDate new];
}

#pragma mark - Accessors.

- (NSDate *)referenceDate {
    NSDate *referenceDate;
    switch (settingCentre.cacheExpiry) {
        case CacheExpiry7Days:
            referenceDate = self.aWeek;
            break;
        case CacheExpiry1Month:
            referenceDate = self.aMonth;
            break;
        case CacheExpiry6Months:
            referenceDate = self.sixMonths;
            break;
        case CacheExpiry12Months:
            referenceDate = self.twelveMonths;
            break;
        case CacheExpiryNoCache:
            // All files in folder would be considered expired.
            referenceDate = [NSDate distantFuture];
            break;
        case CacheExpiryNever:
            // Files would never expire.
            referenceDate = [NSDate distantPast];
            break;
        default:
            referenceDate = [NSDate new];
            break;
    }
    return referenceDate;
}

- (void)setDateOfLastCheck:(NSDate *)dateOfLastCheck {
    if (dateOfLastCheck) {
        [[NSUserDefaults standardUserDefaults] setObject:dateOfLastCheck forKey:kDateOfLastCheck];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDateOfLastCheck];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setDateOfLastClean:(NSDate *)dateOfLastClean {
    if (dateOfLastClean) {
        [[NSUserDefaults standardUserDefaults] setObject:dateOfLastClean forKey:kDateOfLastClean];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDateOfLastClean];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)dateOfLastCheck {
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:kDateOfLastCheck];
    return [date isKindOfClass:[NSDate class]] ? date : nil;
}

- (NSDate *)dateOfLastClean {
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:kDateOfLastClean];
    return [date isKindOfClass:[NSDate class]] ? date : nil;
}

- (NSDate *)aWeek {
    if (!_aWeek) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.day = - 7; // 7 days.
        _aWeek = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] dateByAddingComponents:components toDate:[NSDate new] options:0];
    }
    return _aWeek;
}

- (NSDate *)aMonth {
    if (!_aMonth) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.month = - 1;
        _aMonth = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] dateByAddingComponents:components toDate:[NSDate new] options:0];
    }
    return _aMonth;
}

- (NSDate *)sixMonths {
    if (!_sixMonths) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.month = - 6;
        _sixMonths = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] dateByAddingComponents:components toDate:[NSDate new] options:0];
    }
    return _sixMonths;
}

- (NSDate *)twelveMonths {
    if (!_twelveMonths) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.month = - 12;
        _twelveMonths = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] dateByAddingComponents:components toDate:[NSDate new] options:0];
    }
    return _twelveMonths;
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

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

@end
