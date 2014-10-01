//
//  czzImageManagerViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 14/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzImageManagerViewController.h"
#import "czzImageCentre.h"
#import "czzAppDelegate.h"
#import "Toast+UIView.h"
#import "MWPhoto.h"
#import "MWPhotoBrowser.h"

#define ALL_IMAGE 0
#define FULL_SIZE_IMAGE 1
#define THUMBNAIL 2

@interface czzImageManagerViewController ()<MWPhotoBrowserDelegate>
@property NSMutableArray *Images;
@property NSInteger imageCategory;
@property UIDocumentInteractionController *documentInteractionController;
@property MWPhotoBrowser *photoBrowser;
@property NSMutableArray *photoBrowserDataSource;
@end

@implementation czzImageManagerViewController
@synthesize Images;
@synthesize gallarySegmentControl;
@synthesize imageCategory;
@synthesize documentInteractionController;
@synthesize photoBrowser;
@synthesize photoBrowserDataSource;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
//    //show all images
    imageCategory = ALL_IMAGE;
    if ([[czzImageCentre sharedInstance] ready])
        [self reloadImageFileFromImageCentre];
    else
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"图片还在载入中，请稍后重试..."];
}

#pragma Load data from image centre
-(void)reloadImageFileFromImageCentre{
    Images = [NSMutableArray new];
    if (imageCategory == ALL_IMAGE){
        [Images addObjectsFromArray:[[[czzImageCentre sharedInstance] currentLocalThumbnails] allObjects]];
        [Images addObjectsFromArray:[[[czzImageCentre sharedInstance] currentLocalImages] allObjects]];
    } else if (imageCategory == FULL_SIZE_IMAGE) {
        [Images addObjectsFromArray:[[[czzImageCentre sharedInstance] currentLocalImages] allObjects]];
    } else if (imageCategory == THUMBNAIL){
        [Images addObjectsFromArray:[[[czzImageCentre sharedInstance] currentLocalThumbnails] allObjects]];
    }
    [self.collectionView reloadData];
}

#pragma UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return Images.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"preview_image_cell_identifier" forIndexPath:indexPath];
    NSString *imgFile = [Images objectAtIndex:indexPath.row];
    if (cell && imgFile){
        UIImageView *previewImageView = (UIImageView*)[cell viewWithTag:1];
        UIImage *previewImage = [UIImage imageWithContentsOfFile:imgFile];
        if (previewImage)
            [previewImageView setImage:previewImage];
    }
    return cell;
}

#pragma UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
//    NSString *imgFile = [Images objectAtIndex:indexPath.row];
//    documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:imgFile]];
//    documentInteractionController.delegate = self;
//    [documentInteractionController presentPreviewAnimated:YES];
    [self prepareMWPhotoBrowser];
    photoBrowserDataSource = [NSMutableArray arrayWithArray:Images];
    [photoBrowser setCurrentPhotoIndex:indexPath.row];
    [self.navigationController pushViewController:photoBrowser animated:YES];
}

#pragma UIDocumentInteractionController delegate
-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
}

//show different categories of images
- (IBAction)gallarySegmentControlAction:(id)sender {
    UISegmentedControl *control = (UISegmentedControl*)sender;
    imageCategory = control.selectedSegmentIndex;
    [self reloadImageFileFromImageCentre];
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

-(NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return photoBrowserDataSource.count;
}

-(void)prepareMWPhotoBrowser {
    photoBrowser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    photoBrowser.displayActionButton = YES;
    photoBrowser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    photoBrowser.displaySelectionButtons = YES; // Whether selection buttons are shown on each image (defaults to NO)
    photoBrowser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    photoBrowser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    photoBrowser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    photoBrowser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
    photoBrowser.delayToHideElements = 2.0;

    photoBrowserDataSource = [NSMutableArray new];
}

@end
