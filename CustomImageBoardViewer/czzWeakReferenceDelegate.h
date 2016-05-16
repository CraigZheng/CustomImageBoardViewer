//
//  czzWeakReferenceDelegate.h
//  CustomImageBoardViewer
//
//  Created by Craig on 30/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzWeakReferenceDelegate : NSObject
@property (nonatomic, assign) BOOL isValid;
@property (nonatomic, weak) id delegate;

+(instancetype)weakReferenceDelegate:(id)delegate;

@end
