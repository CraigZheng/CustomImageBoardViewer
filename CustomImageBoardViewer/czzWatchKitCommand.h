//
//  czzWatchKitCommand.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 19/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

#define watchKidCommand @"COMMAND"
#define watchKitCommandLoadMore @"watchKitCommandLoadMore"

typedef NS_ENUM(NSInteger, watchKitCommand) {
    watchKitCommandLoadHomeView = 1,
    watchKitCommandLoadThreadView = 2,
    watchKitCommandLoadForumView = 3,
    watchKitCommandUnknown = 0
};

typedef NS_ENUM(NSInteger, watchKitMiscInfo) {
    watchKitMiscInfoScreenTitleHome = 101,
    watchKitMiscInfoScreenTitleThread = 102,
    wwatchKitMiscInfoScreenTitleUnknown = 100
};

@interface czzWatchKitCommand : NSObject

@end
