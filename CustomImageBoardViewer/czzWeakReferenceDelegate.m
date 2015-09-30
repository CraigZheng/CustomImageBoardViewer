//
//  czzWeakReferenceDelegate.m
//  CustomImageBoardViewer
//
//  Created by Craig on 30/09/2015.
//  Copyright © 2015 Craig. All rights reserved.
//

#import "czzWeakReferenceDelegate.h"

@implementation czzWeakReferenceDelegate

#pragma mark - Getters
-(BOOL)isValid {
    return self.delegate;
}

-(NSUInteger)hash {
    return [self.delegate hash];
}

-(BOOL)isEqual:(id)object{
    return [self.delegate isEqual:object];
}

+(instancetype)weakReferenceDelegate:(id)delegate {
    czzWeakReferenceDelegate *weakReferenceDelegate = [czzWeakReferenceDelegate new];
    weakReferenceDelegate.delegate = delegate;
    
    return weakReferenceDelegate;
}

@end
