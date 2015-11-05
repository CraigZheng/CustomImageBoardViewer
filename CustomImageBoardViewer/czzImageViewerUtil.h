//
//  czzImageViewerUtil.h
//  CustomImageBoardViewer
//
//  Created by Craig on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWPhotoBrowser.h"

@interface czzImageViewerUtil : NSObject <MWPhotoBrowserDelegate>
@property MWPhotoBrowser *photoBrowser;
@property NSMutableArray<NSURL *> *photoBrowserDataSource;
@property UIDocumentInteractionController *documentInteractionController;
@property UINavigationController *photoBrowserNavigationController;

-(void)showPhoto:(NSURL*)photoPath;
-(void)showPhotoWithImage:(UIImage *)image;
-(void)showPhotos:(NSArray*)photos withIndex:(NSInteger)index;
@end
