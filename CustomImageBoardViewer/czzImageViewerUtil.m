//
//  czzImageViewerUtil.m
//  CustomImageBoardViewer
//
//  Created by Craig on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzImageViewerUtil.h"
@interface czzImageViewerUtil ()
@end

@implementation czzImageViewerUtil
@synthesize photoBrowser;
@synthesize photoBrowserDataSource;
@synthesize documentInteractionController;
@synthesize photoBrowserNavigationController;

-(instancetype)init {
    self = [super init];
    if (self) {
        photoBrowserDataSource = [NSMutableArray new];
        [self prepareMWPhotoBrowser];
    }
    return self;
}

-(void)showPhoto:(NSURL *)photoPath {
    if (photoPath && [[czzImageCacheManager sharedInstance] hasImageWithName:photoPath.lastPathComponent]) {
        [self prepareMWPhotoBrowser];
        if (!photoBrowserDataSource)
            photoBrowserDataSource = [NSMutableArray new];
        if (![photoBrowserDataSource containsObject:photoPath])
            [photoBrowserDataSource addObject:photoPath];
        [photoBrowser setCurrentPhotoIndex: [photoBrowserDataSource indexOfObject:photoPath]];
        [self show];
    } else {
        DLog(@"Either photo path is nil");
    }
}

-(void)showPhotoWithImage:(UIImage *)image {
    if (image) {
        [self prepareMWPhotoBrowser];
        photoBrowserDataSource = [@[image] mutableCopy];
        [photoBrowser setCurrentPhotoIndex:0];
        [self show];
    }
}

-(void)showPhotos:(NSArray *)photos withIndex:(NSInteger)index {
    if (photos.count > 0) {
        [self prepareMWPhotoBrowser];
        photoBrowserDataSource = [NSMutableArray arrayWithArray:photos];
        [photoBrowser setCurrentPhotoIndex:index];
        [self show];
    }
    else {
        DLog(@"Either photos or view controller is nil");
    }
}

-(void)show {
    // If top view controller is the main czz navigation controller.
    if (NavigationManager.delegate == [UIApplication rootViewController]) {
        if (NavigationManager.isInTransition) {
            NavigationManager.pushAnimationCompletionHandler = ^{
                if (![[UIApplication topViewController] isKindOfClass:[photoBrowser class]]) {
                    [NavigationManager pushViewController:photoBrowser animated:YES];
                }
            };
        } else {
            if (![[UIApplication topViewController] isKindOfClass:[photoBrowser class]]) {
                [NavigationManager pushViewController:photoBrowser animated:YES];
            }
        }
    } else if ([UIApplication topViewController].navigationController || [[UIApplication topViewController] isKindOfClass:[UINavigationController class]]) {
        // if the top view controller has a navigation controller.
        UINavigationController *naviCon = [UIApplication topViewController].navigationController ? [UIApplication topViewController].navigationController : (UINavigationController *)[UIApplication topViewController];
        if (naviCon) {
            [naviCon pushViewController:photoBrowser animated:YES];
        }
    } else {
        photoBrowserNavigationController = [[UINavigationController alloc] initWithRootViewController:photoBrowser];
        photoBrowserNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [[UIApplication rootViewController] presentViewController:photoBrowserNavigationController animated:YES completion:nil];
    }
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
    photoBrowser.enableSwipeToDismiss = NO; // dont dismiss
    photoBrowser.displayActionButton = YES;
    photoBrowser.hidesBottomBarWhenPushed = YES;

}

#pragma mark - MWPhotoBrowserDelegate
-(id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    @try {
        id source = [photoBrowserDataSource objectAtIndex:index];
        MWPhoto *photo;
        if ([source isKindOfClass:[UIImage class]]) {
            photo = [MWPhoto photoWithImage:source];
        } else {
            photo = [MWPhoto photoWithURL:([source isKindOfClass:[NSURL class]] ? source : [NSURL fileURLWithPath:source])];
        }
        return photo;
    }
    @catch (NSException *exception) {
        DLog(@"%@", exception);
    }
    return nil;
}

-(void)photoBrowser:(MWPhotoBrowser *)browser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    id source = [photoBrowserDataSource objectAtIndex:index];
    if ([source isKindOfClass:[UIImage class]]) {
        // Because the source is an UIImage object, it cannot be open directly by document interaction controller.
        // Must save it temporarily to the disk before openning. 
        NSURL *tempFileURL = [NSURL fileURLWithPath:[[czzAppDelegate libraryFolder] stringByAppendingPathComponent:@"tempImage.jpg"]];
        NSData *data = UIImageJPEGRepresentation((UIImage *)source, 0.99);
        [data writeToURL:tempFileURL atomically:NO];
        documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:tempFileURL];
    } else if ([source isKindOfClass:[NSURL class]]){
        documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:source];
    } else {
        documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:source]];
    }
    UIView *viewToShowDocumentInteractionController;
    if (photoBrowserNavigationController)
        viewToShowDocumentInteractionController = photoBrowserNavigationController.view;
    else
        viewToShowDocumentInteractionController = photoBrowser.view;
    //ipad
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        [documentInteractionController presentOptionsMenuFromBarButtonItem:browser.actionButton animated:YES];
    }
    //iphone
    else {
        [documentInteractionController presentOptionsMenuFromRect:[UIApplication topViewController].view.frame inView:viewToShowDocumentInteractionController animated:YES];
    }
}

-(void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    [photoBrowserNavigationController dismissViewControllerAnimated:YES completion:nil];
}

-(NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return photoBrowserDataSource.count;
}
@end
