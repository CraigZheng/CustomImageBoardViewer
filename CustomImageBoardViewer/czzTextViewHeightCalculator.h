//
//  czzTextViewHeightCalculator.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzTextViewHeightCalculator : NSObject

+(CGFloat)calculatePerfectHeightForContent:(NSAttributedString*)content inView:(UIView*)view;

@end
