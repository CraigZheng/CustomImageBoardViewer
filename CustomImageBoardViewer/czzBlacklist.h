//
//  czzBlacklist.h
//  CustomImageBoardViewer
//
//  Created by Craig on 17/10/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzBlacklist : NSObject
@property NSArray *blacklistEntities;
+ (id)sharedInstance;
@end
