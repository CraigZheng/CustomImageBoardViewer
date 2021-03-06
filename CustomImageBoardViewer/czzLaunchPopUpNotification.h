//
//  czzLaunchPopUpNotification.h
//  CustomImageBoardViewer
//
//  Created by Craig on 24/03/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzLaunchPopUpNotification : NSObject

@property (nonatomic, strong) NSDate *notificationDate;
@property (nonatomic, strong) NSString *notificationContent; // Should be rendered as HTML content.
@property (nonatomic, assign) Boolean enable;
@property (nonatomic, strong) NSString* identifier;

- (instancetype)initWithJson:(NSString *)json;
@end
