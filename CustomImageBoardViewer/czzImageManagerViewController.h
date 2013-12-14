//
//  czzImageManagerViewController.h
//  CustomImageBoardViewer
//
//  Created by Craig on 14/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface czzImageManagerViewController : UICollectionViewController
@property (strong, nonatomic) IBOutlet UISegmentedControl *gallarySegmentControl;
- (IBAction)gallarySegmentControlAction:(id)sender;

@end
