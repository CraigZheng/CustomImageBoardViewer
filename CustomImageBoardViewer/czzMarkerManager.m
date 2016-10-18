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
    NSKeyedArchiver archiveRootObject:self.blockedUIDs toFile:self.mark
    return NO;
}

- (BOOL)restore {
    
    return NO;
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

@end
