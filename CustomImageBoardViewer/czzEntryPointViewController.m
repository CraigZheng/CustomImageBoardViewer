//
//  czzEntryPointViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 26/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzEntryPointViewController.h"
#import "czzForumsViewController.h"
#import "czzHomeViewController.h"

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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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
    czzHomeViewController *centreViewController = [storyboard instantiateViewControllerWithIdentifier:@"home_view_controller"];
    czzForumsViewController *sideViewController = [storyboard instantiateViewControllerWithIdentifier:@"left_side_view_controller"];
    
    self = [super initWithCenterViewController:centreViewController leftViewController:sideViewController];
    self.topController = [storyboard instantiateViewControllerWithIdentifier:@"more_info_view_controller"];

    return self;
}
@end
