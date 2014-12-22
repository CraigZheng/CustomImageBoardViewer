//
//  czzTextViewHeightCalculator.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define IMAGE_HEIGHT 100

#import <Foundation/Foundation.h>
#import "czzThread.h"


@interface czzTextViewHeightCalculator : NSObject

+(CGFloat)calculatePerfectHeightForThreadContent:(czzThread*)thread inView:(UIView*)view hasImage:(BOOL)has;
+(CGFloat)calculatePerfectHeightForThreadContent:(czzThread*)thread inView:(UIView*)view forWidth:(CGFloat)width hasImage:(BOOL)has withExtra:(BOOL)extra;

@end
