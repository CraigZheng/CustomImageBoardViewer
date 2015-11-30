//
//  InterfaceController.h
//  CustomImageBoardViewer WatchKit Extension
//
//  Created by Craig on 9/09/2015.
//  Copyright (c) 2015 Craig. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceController : WKInterfaceController
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *screenTitleLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *wkThreadsTableView;

@end
