//
//  czzBannerNotification.h
//  CustomImageBoardViewer
//
//  Created by Craig on 3/02/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BannerNotificationType) {
    BannerNotificationTypeMessage,
    BannerNotificationTypeMessageWithResponse
};

typedef NS_ENUM(NSInteger, BannerNotificationPosition) {
    BannerNotificationPositionTop,
    BannerNotificationPositionTopBottom
};

@interface czzBannerNotificationUtil : NSObject

+ (void)displayMessage:(NSString *)message position:(BannerNotificationPosition)position;
+ (void)displayMessage:(NSString *)message
              position:(BannerNotificationPosition)position
     userInteractionHandler:(void(^)(void))completionHandler;

@end
