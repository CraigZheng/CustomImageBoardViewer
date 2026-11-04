//
//  czzImageViewerUtil.h
//  CustomImageBoardViewer
//
//  Created by Craig on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface czzImageViewerUtil : NSObject
@property (nonatomic, strong) UIViewController *photoBrowser;
@property (nonatomic, strong) NSMutableArray *photoBrowserDataSource;
@property (nonatomic, strong) UIDocumentInteractionController *documentInteractionController;
@property (nonatomic, strong) UINavigationController *photoBrowserNavigationController;
@property (nonatomic, strong) UIViewController *destinationViewController;

-(void)showPhoto:(NSURL*)photoPath;
-(void)showPhotoWithImage:(UIImage *)image;
-(void)showPhotos:(NSArray*)photos withIndex:(NSInteger)index;
+ (czzImageViewerUtil*)sharedInstance;
@end
