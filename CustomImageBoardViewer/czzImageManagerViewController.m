//
//  czzImageManagerViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 14/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzImageManagerViewController.h"
#import "czzImageCentre.h"

#define ALL_IMAGE 0
#define FULL_SIZE_IMAGE 1
#define THUMBNAIL 2

@interface czzImageManagerViewController ()<UIDocumentInteractionControllerDelegate>
@property NSMutableArray *Images;
@property NSInteger imageCategory;
@property UIDocumentInteractionController *documentInteractionController;
@end

@implementation czzImageManagerViewController
@synthesize Images;
@synthesize gallarySegmentControl;
@synthesize imageCategory;
@synthesize documentInteractionController;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //show all images
    imageCategory = ALL_IMAGE;
    [self reloadImageFileFromImageCentre];
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
    NSString *imgFile = [Images objectAtIndex:indexPath.row];
    documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:imgFile]];
    documentInteractionController.delegate = self;
    [documentInteractionController presentPreviewAnimated:YES];
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
@end
