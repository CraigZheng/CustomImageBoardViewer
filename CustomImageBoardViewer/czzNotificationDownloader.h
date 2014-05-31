//
//  czzNotificationDownloader.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/06/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzNotificationDownloader : NSObject

-(void)downloadNotificationWithVendorID:(NSString*)vendorID;
@end
