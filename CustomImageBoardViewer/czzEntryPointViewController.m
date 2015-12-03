//
//  czzEntryPointViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzEntryPointViewController.h"
#import "czzForumsViewController.h"
#import "czzNavigationController.h"
#import "czzAppDelegate.h"
#import "Toast+UIView.h"

@interface czzEntryPointViewController ()

@end

@implementation czzEntryPointViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    UIStoryboard *storyboard;
    /*
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:Nil];
    }
     */
    storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:Nil];
    czzNavigationController *centreViewController = [czzNavigationController new];
    
    self = [super initWithCenterViewController:centreViewController];
    // The root view controller of the left navigation controller will be the delegate for self.viewDeckController.
    self.delegate = [(UINavigationController *)self.leftController viewControllers][0];
    return self;
}


@end
