//
//  czzPostSenderManager.h
//  CustomImageBoardViewer
//
//  Created by Craig on 22/02/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class czzPostSender;
@interface czzPostSenderManager : NSObject

- (void)firePostSender:(czzPostSender *)postSender;

+ (instancetype)sharedManager;
@end
