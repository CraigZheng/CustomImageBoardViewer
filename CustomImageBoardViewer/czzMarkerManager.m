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

@property (readonly) NSString* markerFolder;
@property (readonly) NSString* markerFilePath;
@property (nonatomic, strong) NSMutableSet<NSString*> *blockedUIDs;
@property (nonatomic, strong) NSMutableSet<NSString*> *highlightedUIDs;

@end

@implementation czzMarkerManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [self save];
    }
    return self;
}

#pragma mark - Content management

- (BOOL)save {
    
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
