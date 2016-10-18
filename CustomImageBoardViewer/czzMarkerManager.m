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

@end

@implementation czzMarkerManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [self save];
    }
    return self;
}

- (BOOL)save {
    
    return NO;
}

- (BOOL)restore {
    return NO;
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

@end
