//
//  czzImageViewerUtil.m
//  CustomImageBoardViewer
//
//  Created by Craig on 7/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzImageViewerUtil.h"
#import "CustomImageBoardViewer-Swift.h"

@implementation czzImageViewerUtil
@synthesize photoBrowser;
@synthesize photoBrowserDataSource;
@synthesize documentInteractionController;
@synthesize photoBrowserNavigationController;

-(instancetype)init {
    self = [super init];
    if (self) {
        photoBrowserDataSource = [NSMutableArray new];
    }
    return self;
}

-(void)showPhoto:(NSURL *)photoPath {
    if (photoPath) {
        photoBrowserDataSource = [NSMutableArray new];
        [photoBrowserDataSource addObject:photoPath.copy];
        [self preparePhotoBrowserWithIndex:0];
        [self show];
    } else {
        DDLogDebug(@"Either photo path is nil");
    }
}

-(void)showPhotoWithImage:(UIImage *)image {
    if (image) {
        photoBrowserDataSource = [@[image] mutableCopy];
        [self preparePhotoBrowserWithIndex:0];
        [self show];
    }
}

-(void)showPhotos:(NSArray *)photos withIndex:(NSInteger)index {
    if (photos.count > 0) {
        photoBrowserDataSource = [NSMutableArray arrayWithArray:photos];
        [self preparePhotoBrowserWithIndex:index];
        [self show];
    }
    else {
        DDLogDebug(@"Either photos or view controller is nil");
    }
}

-(void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.destinationViewController) {
            if ([self.destinationViewController isKindOfClass:[UINavigationController class]]) {
                [(UINavigationController *)self.destinationViewController pushViewControllerWithViewController:photoBrowser animated:YES completion:nil];
            } else {
                photoBrowserNavigationController = [[UINavigationController alloc] initWithRootViewController:photoBrowser];
                photoBrowserNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                photoBrowserNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;
                [self.destinationViewController presentViewController:photoBrowserNavigationController animated:YES completion:nil];
            }
        } else {
            if (NavigationManager.delegate)
            {
                
                if (NavigationManager.isInTransition) {
                    NavigationManager.pushAnimationCompletionHandler = ^{
                        if ([UIApplication topViewController] != photoBrowser) {
                            [[UIApplication topViewController].navigationController pushViewControllerWithViewController:photoBrowser animated:YES completion:nil];
                        }
                    };
                } else {
                    if ([UIApplication topViewController] != photoBrowser) {
                        [[UIApplication topViewController].navigationController pushViewControllerWithViewController:photoBrowser animated:YES completion:nil];
                    }
                }
            }
        }
    });
}

-(void)preparePhotoBrowserWithIndex:(NSInteger)index {
    PhotoBrowserViewController *browser = [[PhotoBrowserViewController alloc] initWithSources:photoBrowserDataSource
                                                                                   startIndex:index];
    __weak typeof(self) weakSelf = self;
    browser.onActionButton = ^(NSInteger photoIndex) {
        [weakSelf presentDocumentInteractionForPhotoAtIndex:photoIndex];
    };
    photoBrowser = browser;
}

-(void)presentDocumentInteractionForPhotoAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)photoBrowserDataSource.count) {
        return;
    }
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
        [documentInteractionController presentOptionsMenuFromRect:CGRectZero inView:[UIApplication topViewController].view animated:YES];
    }
    //iphone
    else {
        [documentInteractionController presentOptionsMenuFromRect:[UIApplication topViewController].view.frame inView:viewToShowDocumentInteractionController animated:YES];
    }
}

+ (czzImageViewerUtil*)sharedInstance {
    static dispatch_once_t p = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}
@end
