//
//  czzImageViewerUtil.m
//  CustomImageBoardViewer
//
//  Created by Craig on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzImageViewerUtil.h"
@interface czzImageViewerUtil ()
@property UIViewController *viewControllerToShow;
@end

@implementation czzImageViewerUtil
@synthesize photoBrowser;
@synthesize photoBrowserDataSource;
@synthesize documentInteractionController;
@synthesize viewControllerToShow;
@synthesize photoBrowserNavigationController;

-(instancetype)init {
    self = [super init];
    if (self) {
        photoBrowserDataSource = [NSMutableArray new];
        [self prepareMWPhotoBrowser];
    }
    return self;
}

-(void)showPhoto:(NSString *)photoPath inViewController:(UIViewController *)viewCon {
    if (photoPath.length > 0 && viewCon) {
        [self prepareMWPhotoBrowser];
        viewControllerToShow = viewCon;
        if (!photoBrowserDataSource)
            photoBrowserDataSource = [NSMutableArray new];
        if (![photoBrowserDataSource containsObject:photoPath])
            [photoBrowserDataSource addObject:photoPath];
        [photoBrowser setCurrentPhotoIndex: [photoBrowserDataSource indexOfObject:photoPath]];
        [self show];
    } else {
        NSLog(@"Either photo path or view controller is nil");
    }
}

-(void)showPhotos:(NSArray *)photos inViewController:(UIViewController *)viewCon withIndex:(NSInteger)index {
    if (photos.count > 0 && viewCon) {
        [self prepareMWPhotoBrowser];
        viewControllerToShow = viewCon;
        photoBrowserDataSource = [NSMutableArray arrayWithArray:photos];
        [photoBrowser setCurrentPhotoIndex:index];
        [self show];
    }
    else {
        NSLog(@"Either photos or view controller is nil");
    }
}

-(void)show {
    photoBrowserNavigationController = [[UINavigationController alloc] initWithRootViewController:photoBrowser];
    photoBrowserNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [viewControllerToShow presentViewController:photoBrowserNavigationController animated:YES completion:^{
    }];
}

-(void)prepareMWPhotoBrowser {
    photoBrowser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    //    browser.displayActionButton = NO; // Show action button to allow sharing, copying, etc (defaults to YES)
    photoBrowser.displayNavArrows = YES; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    photoBrowser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    photoBrowser.zoomPhotosToFill = NO; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    photoBrowser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    photoBrowser.enableGrid = NO; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    photoBrowser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    photoBrowser.delayToHideElements = 4.0;
    photoBrowser.displayActionButton = YES;
}

#pragma mark - MWPhotoBrowserDelegate
-(id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    @try {
        MWPhoto *photo= [MWPhoto photoWithURL:[NSURL fileURLWithPath:[photoBrowserDataSource objectAtIndex:index]]];
        return photo;
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    return nil;
}

-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    NSURL *fileURL = [NSURL fileURLWithPath:[photoBrowserDataSource objectAtIndex:index]];
    documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    UIView *viewToShowDocumentInteractionController = photoBrowserNavigationController.view;
    [documentInteractionController presentOptionsMenuFromRect:CGRectMake(0, 0, viewControllerToShow.view.frame.size.width, viewControllerToShow.view.frame.size.height) inView:viewToShowDocumentInteractionController animated:YES];
}

-(void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    [photoBrowserNavigationController dismissViewControllerAnimated:YES completion:nil];
}

-(NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return photoBrowserDataSource.count;
}
@end
