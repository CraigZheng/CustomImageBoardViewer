//
//  czzMarkerManager.m
//  CustomImageBoardViewer
//
//  Created by Craig on 18/10/16.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzMarkerManager.h"

static NSString * const markerHighlightedFileName = @"marker_highlighted.dat";
static NSString * const markerBlockedFileName = @"marker_blocked.dat";

@interface czzMarkerManager()

@property (nonatomic, readonly) NSString* markerFolder;
@property (nonatomic, readonly) NSString* markerHighlightFilePath;
@property (nonatomic, readonly) NSString* markerBlockedFilePath;
@property (nonatomic, strong) NSMutableSet<NSString*> *blockedUIDs;
@property (nonatomic, strong) NSMutableSet<NSString*> *highlightedUIDs;

@end

@implementation czzMarkerManager

- (instancetype)init {
    self = [super init];
    if (self) {
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
            && [restoredObject isKindOfClass:[NSSet class]]) {
            // Absort the content from restoredObject set.
            self.blockedUIDs = [[NSMutableSet alloc] initWithSet:restoredObject];
        }
        restoredObject = nil;
        if ((restoredObject = [NSKeyedUnarchiver unarchiveObjectWithFile:self.markerHighlightFilePath])
            && [restoredObject isKindOfClass:[NSSet class]]) {
            self.highlightedUIDs = [[NSMutableSet alloc] initWithSet:restoredObject];
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
    self.blockedUIDs = nil;
    self.highlightedUIDs = nil;
    [self save];
}

- (void)highlightUID:(NSString *)UID {
    if (UID.length) {
        [self.highlightedUIDs addObject:UID];
        [self save];
    }
}

- (void)blockUID:(NSString *)UID {
    if (UID.length) {
        [self.blockedUIDs addObject:UID];
        [self save];
    }
}

#pragma mark - Content checking

- (BOOL)isUIDHighlighted:(NSString *)UID {
    return [self.highlightedUIDs containsObject:UID];
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

- (NSMutableSet<NSString *> *)blockedUIDs {
    if (!_blockedUIDs) {
        _blockedUIDs = [NSMutableSet new];
    }
    return _blockedUIDs;
}

- (NSMutableSet<NSString *> *)highlightedUIDs {
    if (!_highlightedUIDs) {
        _highlightedUIDs = [NSMutableSet new];
    }
    return _highlightedUIDs;
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
