//
//  czzShortImageManagerCollectionViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 28/11/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzShortImageManagerCollectionViewController.h"
#import "czzAppDelegate.h"
#import "czzImageCacheManager.h"
#import "czzImageDownloader.h"
#import "czzImageDownloaderManager.h"
#import "czzImageViewerUtil.h"
#import "czzSettingsCentre.h"

@interface czzShortImageManagerCollectionViewController ()<czzImageDownloaderManagerDelegate>
@property (strong, nonatomic) czzImageViewerUtil *imageViewerUtil;
@property (strong, nonatomic) NSArray *downloadedImages;
@property (readonly, nonatomic) NSArray *downloaders;
@end

@implementation czzShortImageManagerCollectionViewController
@synthesize delegate;
@synthesize managerCollectionView;
@synthesize placeholderView;
@synthesize imageViewerUtil;

static NSString * const reuseIdentifier = @"Cell";
static NSString *imageCellIdentifier = @"image_cell_identifier";
static NSString *downloadedImageCellIdentifier = @"downloaded_image_view_cell";

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.definesPresentationContext = YES;
        self.providesPresentationContextTransitionStyle = YES;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    return self;
}

- (void)loadView {
    UIView *rootView = [[UIView alloc] init];
    rootView.backgroundColor = [UIColor clearColor];
    self.view = rootView;

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(90, 100);
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.backgroundColor = [UIColor colorWithRed:0.937 green:0.937 blue:0.957 alpha:1];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:imageCellIdentifier];
    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:downloadedImageCellIdentifier];
    [rootView addSubview:collectionView];
    self.managerCollectionView = collectionView;

    UIView *emptyView = [[UIView alloc] init];
    emptyView.translatesAutoresizingMaskIntoConstraints = NO;
    emptyView.backgroundColor = [UIColor colorWithWhite:0.667 alpha:1];
    [rootView addSubview:emptyView];
    self.placeholderView = emptyView;

    UIImageView *emptyImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"51.png"]];
    emptyImageView.translatesAutoresizingMaskIntoConstraints = NO;
    emptyImageView.contentMode = UIViewContentModeScaleAspectFit;
    [emptyView addSubview:emptyImageView];

    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    emptyLabel.text = @"没有下载中的图片～";
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.font = [UIFont systemFontOfSize:14];
    emptyLabel.textColor = [UIColor colorWithRed:0.6 green:0.4 blue:0.2 alpha:1];
    [emptyView addSubview:emptyLabel];

    UITapGestureRecognizer *backgroundTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnBackgroundViewAction:)];
    backgroundTap.cancelsTouchesInView = NO;
    [rootView addGestureRecognizer:backgroundTap];

    UILayoutGuide *safeArea = rootView.safeAreaLayoutGuide;
    NSLayoutConstraint *collectionHeight = [collectionView.heightAnchor constraintEqualToConstant:320];
    collectionHeight.priority = 250;
    [NSLayoutConstraint activateConstraints:@[
        [collectionView.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
        [collectionView.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],
        [collectionView.centerXAnchor constraintEqualToAnchor:rootView.centerXAnchor],
        [collectionView.centerYAnchor constraintEqualToAnchor:rootView.centerYAnchor],
        collectionHeight,
        [collectionView.topAnchor constraintGreaterThanOrEqualToAnchor:safeArea.topAnchor constant:60],
        [safeArea.bottomAnchor constraintGreaterThanOrEqualToAnchor:collectionView.bottomAnchor constant:60],

        [emptyView.centerXAnchor constraintEqualToAnchor:rootView.centerXAnchor],
        [emptyView.centerYAnchor constraintEqualToAnchor:rootView.centerYAnchor],
        [emptyView.widthAnchor constraintEqualToConstant:160],
        [emptyView.heightAnchor constraintEqualToConstant:132],
        [emptyImageView.centerXAnchor constraintEqualToAnchor:emptyView.centerXAnchor],
        [emptyImageView.centerYAnchor constraintEqualToAnchor:emptyView.centerYAnchor],
        [emptyImageView.widthAnchor constraintEqualToConstant:80],
        [emptyImageView.heightAnchor constraintEqualToConstant:80],
        [emptyLabel.leadingAnchor constraintEqualToAnchor:emptyView.leadingAnchor constant:8],
        [emptyLabel.trailingAnchor constraintEqualToAnchor:emptyView.trailingAnchor constant:-8],
        [emptyView.bottomAnchor constraintEqualToAnchor:emptyLabel.bottomAnchor]
    ]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = settingCentre.transparentBackgroundColour;
    [[czzImageDownloaderManager sharedManager] addDelegate:self];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [managerCollectionView reloadData];
    if (self.downloadedImages.count == 0 && self.downloaders.count == 0)
    {
        placeholderView.hidden = NO;
    } else {
        placeholderView.hidden = YES;
    }
}

- (IBAction)tapOnBackgroundViewAction:(id)sender {
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);
    UITapGestureRecognizer *tapSender = sender;
    // If the tap gesture is located outside of the collection view.
    DDLogDebug(@"");
    if (!CGRectContainsPoint(self.managerCollectionView.frame, [tapSender locationInView:self.view])) {
        [self dismissWithCompletionHandler:nil];
    }
}

- (void)dismissWithCompletionHandler:(void(^)(void))completionHandler {
    BOOL isModalView = [self isModal];
    if (self.navigationController.viewControllers.count > 1) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            if (completionHandler) {
                completionHandler();
            }
        }];
        
        [self.navigationController popViewControllerAnimated:YES];
        [CATransaction commit];
        
    } else if (isModalView) {
        [self dismissViewControllerAnimated:YES completion:^{
            if (completionHandler) {
                completionHandler();
            }
        }];
    } else {
        DDLogDebug(@"%s: cannot dismiss.", __PRETTY_FUNCTION__);
    }
}

#pragma mark - Getter
-(NSArray *)downloaders {
    return [[[czzImageDownloaderManager sharedManager] imageDownloaders] allObjects];
}

-(NSArray *)downloadedImages {
    // Reverse the downloaded images.
    return [[[[czzImageDownloaderManager sharedManager] downloadedImages] reverseObjectEnumerator] allObjects];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0)
        return self.downloaders.count;
    return self.downloadedImages.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:imageCellIdentifier forIndexPath:indexPath];
        if ([cell viewWithTag:1] == nil) {
            UIImageView *thumbnailView = [[UIImageView alloc] init];
            thumbnailView.translatesAutoresizingMaskIntoConstraints = NO;
            thumbnailView.tag = 1;
            thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
            [cell.contentView addSubview:thumbnailView];
            UILabel *progressLabel = [[UILabel alloc] init];
            progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
            progressLabel.tag = 2;
            progressLabel.textAlignment = NSTextAlignmentCenter;
            progressLabel.font = [UIFont systemFontOfSize:12];
            progressLabel.adjustsFontSizeToFitWidth = YES;
            progressLabel.minimumScaleFactor = 0.5;
            [cell.contentView addSubview:progressLabel];
            [NSLayoutConstraint activateConstraints:@[
                [thumbnailView.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
                [thumbnailView.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor],
                [thumbnailView.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor],
                [cell.contentView.bottomAnchor constraintEqualToAnchor:thumbnailView.bottomAnchor constant:20],
                [progressLabel.topAnchor constraintEqualToAnchor:thumbnailView.bottomAnchor constant:2],
                [progressLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor],
                [progressLabel.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor],
                [cell.contentView.bottomAnchor constraintEqualToAnchor:progressLabel.bottomAnchor]
            ]];
        }
        
        UIImageView *downloaderThumbnailImageView = (UIImageView*) [cell viewWithTag:1];
        UILabel *downloaderLabel = (UILabel*) [cell viewWithTag:2];
        czzImageDownloader *currentDownloader = [self.downloaders objectAtIndex:indexPath.row];
        //thumbnail
        UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:[[czzAppDelegate thumbnailFolder] stringByAppendingPathComponent:[[currentDownloader targetURLString] lastPathComponent]]];
        if (thumbnailImage) {
            downloaderThumbnailImageView.image = thumbnailImage;
        } else {
            downloaderThumbnailImageView.image = [UIImage imageNamed:@"icon.png"];
        }
        //progress label
        NSString *progressText = [NSString stringWithFormat:@"%.1f%%", [currentDownloader progress] * 100];
        downloaderLabel.text = progressText;
        return cell;
    } else {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:downloadedImageCellIdentifier forIndexPath:indexPath];
        if ([cell viewWithTag:1] == nil) {
            UIImageView *thumbnailView = [[UIImageView alloc] init];
            thumbnailView.translatesAutoresizingMaskIntoConstraints = NO;
            thumbnailView.tag = 1;
            thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
            [cell.contentView addSubview:thumbnailView];
            [NSLayoutConstraint activateConstraints:@[
                [thumbnailView.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
                [thumbnailView.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor],
                [thumbnailView.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor],
                [thumbnailView.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor]
            ]];
        }
        
        UIImageView *thumbnailImageView = (UIImageView*) [cell viewWithTag:1];
        NSString *imgPath = [self.downloadedImages objectAtIndex:indexPath.row];
        UIImage *fullImg = [UIImage imageWithContentsOfFile:imgPath];
        UIImage *thumbnailImg = [UIImage imageWithContentsOfFile:[[czzAppDelegate thumbnailFolder] stringByAppendingPathComponent:imgPath.lastPathComponent]];
        
        thumbnailImageView.image = thumbnailImg ? thumbnailImg : fullImg;
        
        return cell;
    }
}

#pragma mark - UICollectionView delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        czzImageDownloader *imageDownloader = [self.downloaders objectAtIndex:indexPath.row];
        [[czzImageDownloaderManager sharedManager] stopDownloadingImage:imageDownloader.imageURLString.lastPathComponent];
        [self dismissWithCompletionHandler:nil];
    }
    //downloaded image section
    else if (indexPath.section == 1) {
        // Dismiss then show the image.
        [self dismissWithCompletionHandler:^{
            if ([delegate respondsToSelector:@selector(shortImageManager:selectedImageWithIndex:inImages:)]) {
                [delegate shortImageManager:self selectedImageWithIndex:indexPath.row inImages:[self.downloadedImages copy]];
            } else {
                imageViewerUtil = [czzImageViewerUtil new];
                [imageViewerUtil showPhotos:self.downloadedImages withIndex:indexPath.row];
            }
        }];
    }
}

#pragma mark - czzImageDownloaderManagerDelegate
-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedUpdated:(czzImageDownloader *)downloader imageName:(NSString *)imageName progress:(CGFloat)progress {
    [self.managerCollectionView reloadData];
}

-(void)imageDownloaderManager:(czzImageDownloaderManager *)manager downloadedFinished:(czzImageDownloader *)downloader imageName:(NSString *)imageName wasSuccessful:(BOOL)success {
    // This view controller cares only for the full size images.
    if (!downloader.isThumbnail) {
        [self.managerCollectionView reloadData];
    }
}

+ (instancetype)new {
    return [[self alloc] init];
}
@end
