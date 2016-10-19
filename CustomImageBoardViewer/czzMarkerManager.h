//
//  czzMarkerManager.h
//  CustomImageBoardViewer
//
//  Created by Craig on 18/10/16.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzMarkerManager : NSObject

- (void)highlightUID:(NSString *)UID;
- (void)blockUID:(NSString *)UID;
- (void)unHighlightUID:(NSString *)UID;
- (void)unBlockUID:(NSString *)UID;
- (BOOL)isUIDHighlighted:(NSString *)UID;
- (BOOL)isUIDBlocked:(NSString *)UID;
- (BOOL)save;
- (BOOL)restore;
- (void)reset;
+ (instancetype)sharedInstance;

@end
