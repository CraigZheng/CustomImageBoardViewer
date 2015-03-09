//
//  NSObject+Extension.h
//  CustomImageBoardViewer
//
//  Created by Craig on 9/03/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Extension)
-(id)readFromJsonDictionary:(NSDictionary*)dict withName:(NSString*)name;
@end
