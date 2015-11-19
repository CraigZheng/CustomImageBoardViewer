//
//  czzWatchKitCommand.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 19/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kWatchkitCommandCaller;
extern NSString * const kWatchkitCommandAction;
extern NSString * const kWatchkitCommandParameter;

typedef NS_ENUM(NSInteger, watchkitCommandAction) {
    watchKitCommandLoadHomeView = 1,
    watchKitCommandLoadThreadView = 2,
    watchKitCommandLoadForumView = 3,
    watchKitCommandWatchThread = 4,
    watchKitCommandLoadImage = 5,
    watchKitCommandUnknown = 0
};

@interface czzWatchKitCommand : NSObject
@property (nonatomic, strong) id caller;
@property (nonatomic, assign) watchkitCommandAction action;
@property (nonatomic, strong) NSDictionary *parameter;
@end
