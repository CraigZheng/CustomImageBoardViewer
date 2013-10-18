//
//  czzBlacklistEntity.h
//  CustomImageBoardViewer
//
//  Created by Craig on 17/10/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzBlacklistEntity : NSObject
@property NSInteger ID;
@property NSInteger threadID;
@property NSDate *date;
@property NSString *reason;
@property BOOL content;
@property BOOL image;
@property BOOL harmful;

-(BOOL)isReady;
-(NSData*)requestBody;
@end
