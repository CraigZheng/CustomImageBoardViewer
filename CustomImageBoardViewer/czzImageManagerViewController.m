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
#import "czzImageViewerUtil.h"

#define ALL_IMAGE 0
#define FULL_SIZE_IMAGE 1
#define THUMBNAIL 2

@interface czzImageManagerViewController ()
@property NSMutableArray *Images;
@property NSInteger imageCategory;
@property czzImageViewerUtil *imageViewerUtil;
@end

@implementation czzImageManagerViewController
@synthesize Images;
@synthesize gallarySegmentControl;
@synthesize imageCategory;
@synthesize imageViewerUtil;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
    imageViewerUtil = [czzImageViewerUtil new];
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
        [Images addObjectsFromArray:[[czzImageCentre sharedInstance] localThumbnailsArray]];
        [Images addObjectsFromArray:[[czzImageCentre sharedInstance] localImagesArray]];
    } else if (imageCategory == FULL_SIZE_IMAGE) {
        [Images addObjectsFromArray:[[czzImageCentre sharedInstance] localImagesArray]];
    } else if (imageCategory == THUMBNAIL){
        [Images addObjectsFromArray:[[czzImageCentre sharedInstance] localThumbnailsArray]];
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat quaterWidth = self.view.frame.size.width / 4;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        quaterWidth = self.view.frame.size.width / 6;
    return CGSizeMake(quaterWidth, quaterWidth);
}

#pragma UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [imageViewerUtil showPhotos:Images inViewController:self withIndex:indexPath.row];
}

//show different categories of images
- (IBAction)gallarySegmentControlAction:(id)sender {
    UISegmentedControl *control = (UISegmentedControl*)sender;
    imageCategory = control.selectedSegmentIndex;
    [self reloadImageFileFromImageCentre];
}

#pragma mark memory pressure
-(void)didReceiveMemoryWarning {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
    [[czzAppDelegate sharedAppDelegate].window makeToast:@"内存不足，退出图片管理器以避免崩溃"];
}

@end
