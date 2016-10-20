//
//  czzMarkerManager.m
//  CustomImageBoardViewer
//
//  Created by Craig on 18/10/16.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzMarkerManager.h"

#import "CustomImageBoardViewer-Swift.h"

static NSString * const markerHighlightedFileName = @"marker_highlighted.dat";
static NSString * const markerBlockedFileName = @"marker_blocked.dat";

@interface czzMarkerManager()

@property (nonatomic, readonly) NSString* markerFolder;
@property (nonatomic, readonly) NSString* markerHighlightFilePath;
@property (nonatomic, readonly) NSString* markerBlockedFilePath;
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *blockedUIDs;
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *highlightedUIDs;
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *pendingHighlightUIDs;

@end

@implementation czzMarkerManager

- (instancetype)init {
    self = [super init];
    if (self) {
        // Create Marker folder if necessary.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:self.markerFolder]) {
            [fileManager createDirectoryAtPath:self.markerFolder
                   withIntermediateDirectories:NO
                                    attributes:@{NSFileProtectionKey:NSFileProtectionNone}
                                         error:nil];
        }
        [self restore];
    }
    return self;
}

#pragma mark - Content management

- (BOOL)save {
    BOOL success = YES;
    if (![NSKeyedArchiver archiveRootObject:self.blockedUIDs toFile:self.markerBlockedFilePath]) {
        DLog(@"Failed to save blockedUIDs.");
        success = NO;
    }
    if (![NSKeyedArchiver archiveRootObject:self.highlightedUIDs toFile:self.markerHighlightFilePath]) {
        DLog(@"Failed to save highlightedUIDs.");
        success = NO;
    }
    return success;
}

- (BOOL)restore {
    BOOL success = YES;
    id restoredObject;
    @try {
        // Restore blockedUIDs set.
        if ((restoredObject = [NSKeyedUnarchiver unarchiveObjectWithFile:self.markerBlockedFilePath])
            && [restoredObject isKindOfClass:[NSOrderedSet class]]) {
            // Absort the content from restoredObject set.
            self.blockedUIDs = [[NSMutableOrderedSet alloc] initWithOrderedSet:restoredObject];
        }
        restoredObject = nil;
        if ((restoredObject = [NSKeyedUnarchiver unarchiveObjectWithFile:self.markerHighlightFilePath])
            && [restoredObject isKindOfClass:[NSOrderedSet class]]) {
            self.highlightedUIDs = [[NSMutableOrderedSet alloc] initWithOrderedSet:restoredObject];
        }
    } @catch (NSException *exception) {
        DLog(@"%@", exception);
        success = NO;
        // Reset both back to nil.
        self.blockedUIDs = nil;
        self.highlightedUIDs = nil;
    }
    return success;
}

- (void)reset {
    // Reset contents.
    for (NSString *UID in self.highlightedUIDs) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:UID];
    }
    self.blockedUIDs = nil;
    self.highlightedUIDs = nil;
    [self save];
}

- (void)prepareToHighlightUID:(NSString *)UID {
    if (UID.length) {
        [self.pendingHighlightUIDs addObject:UID];
    }
}

- (void)highlightUID:(NSString *)UID withColour:(UIColor *)colour {
    if (UID.length && colour) {
        [self.highlightedUIDs addObject:UID];
        // Remove the save object from pending set.
        [self.pendingHighlightUIDs removeObject:UID];
        // Save the associated colour to NSUserDefaults.
        [[NSUserDefaults standardUserDefaults] setColor:colour forKey:UID];
        [self save];
    }
}

- (void)blockUID:(NSString *)UID {
    if (UID.length) {
        [self.blockedUIDs addObject:UID];
        [self save];
    }
}

- (void)unHighlightUID:(NSString *)UID {
    if (UID.length) {
        [self.highlightedUIDs removeObject:UID];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:UID];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self save];
    }
}

- (void)unBlockUID:(NSString *)UID {
    if (UID.length) {
        [self.blockedUIDs removeObject:UID];
        [self save];
    }
}

#pragma mark - Content checking

- (UIColor *)highlightColourForUID:(NSString *)UID {
    return [[NSUserDefaults standardUserDefaults] colorForKey:UID];
}

- (BOOL)isUIDBlocked:(NSString *)UID {
    return [self.blockedUIDs containsObject:UID];
}

#pragma mark - Getters

- (NSString *)markerFolder {
    NSString *markerFolder = [[czzAppDelegate documentFolder] stringByAppendingPathComponent:@"Marker"];
    return markerFolder;
}

- (NSString *)markerHighlightFilePath {
    return [self.markerFolder stringByAppendingPathComponent:markerHighlightedFileName];
}

- (NSString *)markerBlockedFilePath {
    return [self.markerFolder stringByAppendingPathComponent:markerBlockedFileName];
}

- (NSMutableOrderedSet<NSString *> *)blockedUIDs {
    if (!_blockedUIDs) {
        _blockedUIDs = [NSMutableOrderedSet new];
    }
    return _blockedUIDs;
}

- (NSMutableOrderedSet<NSString *> *)highlightedUIDs {
    if (!_highlightedUIDs) {
        _highlightedUIDs = [NSMutableOrderedSet new];
    }
    return _highlightedUIDs;
}

- (NSMutableOrderedSet<NSString *> *)pendingHighlightUIDs {
    if (!_pendingHighlightUIDs) {
        _pendingHighlightUIDs = [NSMutableOrderedSet new];
    }
    return _pendingHighlightUIDs;
}

+ (instancetype)sharedInstance
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

@end
