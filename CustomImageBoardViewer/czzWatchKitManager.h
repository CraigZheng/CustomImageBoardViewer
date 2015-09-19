//
//  czzWatchKitManager.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 18/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzWatchKitManager : NSObject
-(void)handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply withBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier;

+(instancetype)sharedManager;
@end
