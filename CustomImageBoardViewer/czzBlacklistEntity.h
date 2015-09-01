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
@property (strong, nonatomic) NSString *reason;
@property (assign, nonatomic) BOOL content;
@property (assign, nonatomic) BOOL image;
@property (assign, nonatomic) BOOL harmful;
@property (assign, nonatomic) BOOL block;

-(BOOL)isReady;
-(NSData*)requestBody;
@end
