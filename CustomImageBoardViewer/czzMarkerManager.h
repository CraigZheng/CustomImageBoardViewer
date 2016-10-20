//
//  czzMarkerManager.h
//  CustomImageBoardViewer
//
//  Created by Craig on 18/10/16.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface czzMarkerManager : NSObject
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> * _Nonnull blockedUIDs;
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> * _Nonnull highlightedUIDs;
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> * _Nonnull pendingHighlightUIDs;

- (void)prepareToHighlightUID:(NSString * _Nonnull)UID;
- (void)highlightUID:(NSString * _Nonnull)UID withColour:(UIColor * _Nonnull)colour;
- (void)blockUID:(NSString * _Nonnull)UID;
- (void)unHighlightUID:(NSString * _Nonnull)UID;
- (void)unBlockUID:(NSString * _Nonnull)UID;
- (UIColor * _Nullable)highlightColourForUID:(NSString * _Nonnull)UID;
- (BOOL)isUIDBlocked:(NSString * _Nonnull)UID;
- (BOOL)save;
- (BOOL)restore;
- (void)reset;
+ (instancetype _Nonnull)sharedInstance;

@end
