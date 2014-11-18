//
//  czzOnScreenImageManagerViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 18/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzOnScreenImageManagerViewController.h"

@interface czzOnScreenImageManagerViewController ()

@end

@implementation czzOnScreenImageManagerViewController
@synthesize mainIcon;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithWhite:1. alpha:0.1];
    CAShapeLayer *circle = [CAShapeLayer layer];
    // Make a circular shape
    UIBezierPath *circularPath=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, mainIcon.frame.size.width, mainIcon.frame.size.height) cornerRadius:MAX(mainIcon.frame.size.width, mainIcon.frame.size.height)];
    
    circle.path = circularPath.CGPath;
    
    // Configure the apperence of the circle
    circle.fillColor = [UIColor blackColor].CGColor;
    circle.strokeColor = [UIColor blackColor].CGColor;
    circle.lineWidth = 0;
    
    mainIcon.layer.mask=circle;
    
    mainIcon.layer.shadowRadius = 5.0;
    mainIcon.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    mainIcon.layer.shadowOpacity = 0.8;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
