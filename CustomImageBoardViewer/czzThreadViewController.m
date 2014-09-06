//
//  czzThreadViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig on 27/09/13.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzThreadViewController.h"
#import "czzXMLDownloader.h"
//#import "czzXMLProcessor.h"
#import "czzJSONProcessor.h"
#import "czzThread.h"
#import "Toast+UIView.h"
#import "SMXMLDocument.h"
#import "czzImageCentre.h"
#import "czzImageDownloader.h"
#import "czzAppDelegate.h"
#import "czzRightSideViewController.h"
#import "DACircularProgressView.h"
#import "czzThreadCacheManager.h"
#import "czzHomeViewController.h"
#import "czzMenuEnabledTableViewCell.h"
#import "czzThreadRefButton.h"
#import "PartialTransparentView.h"
#import "czzOnScreenCommandViewController.h"
#import "czzSearchViewController.h"
#import "czzSettingsCentre.h"

#define WARNINGHEADER @"**** 用户举报的不健康的内容 ****\n\n"
#define OVERLAY_VIEW 122

@interface czzThreadViewController ()<czzXMLDownloaderDelegate, /*czzXMLProcessorDelegate,*/ czzJSONProcessorDelegate, UIDocumentInteractionControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>
@property NSString *baseURLString;
@property NSString *targetURLString;
@property NSMutableArray *threads;
@property czzXMLDownloader *xmlDownloader;
@property NSIndexPath *selectedIndex;
@property czzRightSideViewController *threadMenuViewController;
@property NSInteger pageNumber;
@property NSMutableDictionary *downloadedImages;
@property NSMutableSet *currentImageDownloaders;
@property UIDocumentInteractionController *documentInteractionController;
@property CGPoint threadsTableViewContentOffSet; //record the content offset of the threads tableview
@property UITapGestureRecognizer *tapOnImageGestureRecogniser;
@property czzThread *shouldHighlightSelectedThread;
@property BOOL shouldHighlight;
@property NSMutableArray *heightsForRows;
@property NSMutableArray *heightsForRowsForHorizontal;
@property czzOnScreenCommandViewController *onScreenCommand;
@property CGPoint restoreFromBackgroundOffSet;
@property BOOL shouldDisplayQuickScrollCommand;
@property NSString *thumbnailFolder;
@property NSString *keywordToSearch;
@property czzSettingsCentre *settingsCentre;
@end

@implementation czzThreadViewController
@synthesize baseURLString;
@synthesize targetURLString;
//@synthesize originalThreadData;
@synthesize threads;
@synthesize xmlDownloader;
@synthesize threadTableView;
@synthesize selectedIndex;
@synthesize threadMenuViewController;
@synthesize parentThread;
@synthesize pageNumber;
@synthesize downloadedImages;
@synthesize currentImageDownloaders;
@synthesize documentInteractionController;
@synthesize tapOnImageGestureRecogniser;
@synthesize threadsTableViewContentOffSet;
@synthesize shouldHighlight;
@synthesize shouldHighlightSelectedThread;
@synthesize heightsForRows;
@synthesize heightsForRowsForHorizontal;
@synthesize onScreenCommand;
@synthesize restoreFromBackgroundOffSet;
@synthesize shouldDisplayQuickScrollCommand;
@synthesize thumbnailFolder;
@synthesize keywordToSearch;
@synthesize settingsCentre;
@synthesize shouldHideImageForThisForum;

- (void)viewDidLoad
{
    [super viewDidLoad];
    //thumbnail folder
    thumbnailFolder = [czzAppDelegate libraryFolder];
    thumbnailFolder = [thumbnailFolder stringByAppendingPathComponent:@"Thumbnails"];
    //settings
    settingsCentre = [czzSettingsCentre sharedInstance];
    shouldHighlight = settingsCentre.userDefShouldHighlightPO;
    baseURLString = [settingsCentre.thread_content_host stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)self.parentThread.ID]];
    pageNumber = 1;
    downloadedImages = [NSMutableDictionary new];
    threads = [NSMutableArray new];
    heightsForRows = [NSMutableArray new];
    heightsForRowsForHorizontal = [NSMutableArray new];
    currentImageDownloaders = [[czzImageCentre sharedInstance] currentImageDownloaders];
    //add the UIRefreshControl to uitableview
    UIRefreshControl *refreCon = [[UIRefreshControl alloc] init];
    [refreCon addTarget:self action:@selector(dragOnRefreshControlAction:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreCon;
    self.viewDeckController.rightSize = self.view.frame.size.width/4;
    self.navigationController.delegate = self;
    //try to retrive cached thread from storage
    NSArray *cachedThreads = [[czzThreadCacheManager sharedInstance] readThreads:parentThread];
    if (cachedThreads){
        [threads addObjectsFromArray:cachedThreads];
    } else {
        [threads addObject:parentThread];
    }
    NSDictionary *cachedHeights = [[czzThreadCacheManager sharedInstance] readHeightsForThread:parentThread];
    if (cachedHeights) {
        [heightsForRows addObjectsFromArray:[cachedHeights objectForKey:@"VerticalHeights"]];
        [heightsForRowsForHorizontal addObjectsFromArray:[cachedHeights objectForKey:@"HorizontalHeights"]];
    }
    pageNumber = (threads.count - 1)/ 20 + 1;
    [self loadMoreThread:pageNumber];

    //end of retriving cached thread from storage
    //Initialise the tap gesture recogniser, it is to be used on the Image Views in the cell
    tapOnImageGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTapInImage:)];
    
    //set up custom edit menu
    UIMenuItem *replyMenuItem = [[UIMenuItem alloc] initWithTitle:@"回复" action:@selector(menuActionReply:)];
    UIMenuItem *copyMenuItem = [[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(menuActionCopy:)];
    UIMenuItem *openMenuItem = [[UIMenuItem alloc] initWithTitle:@"打开链接" action:@selector(menuActionOpen:)];
    UIMenuItem *highlightMenuItem = [[UIMenuItem alloc] initWithTitle:@"高亮他" action:@selector(menuActionHighlight:)];
    UIMenuItem *searchMenuItem = [[UIMenuItem alloc] initWithTitle:@"搜索他" action:@selector(menuActionSearch:)];
    [[UIMenuController sharedMenuController] setMenuItems:@[replyMenuItem, copyMenuItem, highlightMenuItem, searchMenuItem, openMenuItem]];
    [[UIMenuController sharedMenuController] update];
    //show on screen command
    onScreenCommand = [[czzOnScreenCommandViewController alloc] initWithNibName:@"czzOnScreenCommandViewController" bundle:[NSBundle mainBundle]];
    onScreenCommand.tableviewController = self;
    [onScreenCommand hide];
    shouldDisplayQuickScrollCommand = settingsCentre.userDefShouldShowOnScreenCommand;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //configure the right view as menu
    UINavigationController *rightController = [self.storyboard instantiateViewControllerWithIdentifier:@"right_menu_view_controller"];    threadMenuViewController = [rightController.viewControllers objectAtIndex:0];
    threadMenuViewController.parentThread = parentThread;
    threadMenuViewController.selectedThread = parentThread;
    self.viewDeckController.rightController = rightController;
    //disable left controller
    self.viewDeckController.leftController = nil;
    //register for nsnotification centre for image downloaded notification and download progress update notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaded:) name:@"ThumbnailDownloaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaded:) name:@"ImageDownloaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaderUpdated:) name:@"ImageDownloaderProgressUpdated" object:nil];
    //Jump to command observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PromptForJumpToPage) name:@"JumpToPageCommand" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(HighlightThreadSelected:) name:@"HighlightAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SearchUser:) name:@"SearchAction" object:nil];

    //indicate thread view controller is currently active
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setObject:[NSNumber numberWithBool:YES] forKey:@"ThreadViewControllerActive"];
    [userDef synchronize];
    //scroll to restore from background content off set
    if (!CGPointEqualToPoint(CGPointZero, restoreFromBackgroundOffSet)) {
        threadTableView.contentOffset = restoreFromBackgroundOffSet;
        restoreFromBackgroundOffSet = CGPointZero;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //hide on screen command
    [onScreenCommand hide];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"FirstTimeViewingThread"]){
        [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"长按帖子以回复" duration:2.0 position:@"center" title:@"请注意"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"FirstTimeViewingThread"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
#pragma mark - enter/exiting background
-(void)prepareToEnterBackground {
    if (threads.count > 1)
        [self saveThreadsToCache];
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setObject:[NSNumber numberWithFloat:threadTableView.contentOffset.y] forKey:@"ThreadViewContentOffSetY"];
    [userDef synchronize];
}

-(void)restoreFromBackground {
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    if ([userDef objectForKey:@"ThreadViewContentOffSetY"]) {
        CGFloat offSetY = [[userDef objectForKey:@"ThreadViewContentOffSetY"] floatValue];
        restoreFromBackgroundOffSet = CGPointMake(0, offSetY);
    }

    [userDef removeObjectForKey:@"ThreadViewContentOffSetY"];
    [userDef synchronize];
}

#pragma mark - UINavigationController
-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    //if this view controller is about to be poped from view stack, stop any downloading and save threads to storage
    if ([viewController isKindOfClass:[czzHomeViewController class]]){
        //stop any downloading xml
        if (xmlDownloader){
            [xmlDownloader stop];
            xmlDownloader = nil;
        }
        NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
        [userDef setObject:[NSNumber numberWithBool:NO] forKey:@"ThreadViewControllerActive"];
        [userDef synchronize];
        [self saveThreadsToCache];
        self.navigationController.delegate = nil;
    }
}

-(void)saveThreadsToCache {
    //save threads to storage
    [[czzThreadCacheManager sharedInstance] saveThreads:threads forThread:parentThread];
    [[czzThreadCacheManager sharedInstance] saveVerticalHeights:heightsForRows andHorizontalHeighs:heightsForRowsForHorizontal ForThread:parentThread];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (threads.count > 0)
        return threads.count + 1;
    return threads.count;
}

#pragma mark UITableView delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"thread_cell_identifier";
    if (indexPath.row == threads.count){
        UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:@"load_more_cell_identifier"];
        if (xmlDownloader) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"loading_cell_identifier"];
            UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView*)[cell viewWithTag:2];
            [activityIndicator startAnimating];
        } else if (parentThread.responseCount > 20 && ((pageNumber - 1) * 20 + threads.count % 20 - 1) < parentThread.responseCount){

            cell = [tableView dequeueReusableCellWithIdentifier:@"load_more_cell_identifier"];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"no_more_cell_identifier"];
        }
        return cell;
    }
    czzThread *thread = [threads objectAtIndex:indexPath.row];
    //if image is present
    if (thread.thImgSrc.length != 0){
        CellIdentifier = @"image_thread_cell_identifier";
    }
    czzMenuEnabledTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    // Configure the cell...
    if (cell){
        cell.myThread = thread;

        //set the title of this thread
        if (indexPath.row == 0)
            self.title = thread.title;

        //construct UI elements
        
        UITextView *contentTextView = (UITextView*)[cell viewWithTag:1];
        UILabel *idLabel = (UILabel*)[cell viewWithTag:2];
        UILabel *posterLabel = (UILabel*)[cell viewWithTag:3];
        UILabel *dateLabel = (UILabel*)[cell viewWithTag:5];
        UILabel *sageLabel = (UILabel*)[cell viewWithTag:7];
        UILabel *lockLabel = (UILabel*)[cell viewWithTag:8];
        UIImageView *previewImageView = (UIImageView*)[cell viewWithTag:9];
        previewImageView.hidden = YES;
        DACircularProgressView *circularProgressView = (DACircularProgressView*)[cell viewWithTag:10];
        circularProgressView.hidden = YES;
        if (thread.thImgSrc.length != 0){
            previewImageView.hidden = NO;
            [previewImageView setImage:[UIImage imageNamed:@"Icon.png"]];
            NSString *filePath = [thumbnailFolder stringByAppendingPathComponent:[thread.thImgSrc.lastPathComponent stringByReplacingOccurrencesOfString:@"~/" withString:@""]];
            UIImage *previewImage =[[UIImage alloc] initWithContentsOfFile:filePath];
            if (previewImage){
                [previewImageView setImage:previewImage];
            } else if ([downloadedImages objectForKey:thread.thImgSrc]){
              [previewImageView setImage:[[UIImage alloc] initWithContentsOfFile:[downloadedImages objectForKey:thread.thImgSrc]]];
            }
            //assign a gesture recogniser to it
            [previewImageView setGestureRecognizers:@[tapOnImageGestureRecogniser]];
        }
        //if harmful flag is set, display warning header of harmful thread
        NSMutableAttributedString *contentAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:thread.content];
        if (thread.harmful){
            NSDictionary *warningStringAttributes = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObject:[UIColor lightGrayColor]] forKeys:[NSArray arrayWithObject:NSForegroundColorAttributeName]];
            NSAttributedString *warningAttString = [[NSAttributedString alloc] initWithString:WARNINGHEADER attributes:warningStringAttributes];
            
            //add the warning header to the front of content attributed string
            contentAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:warningAttString];
            [contentAttrString insertAttributedString:thread.content atIndex:warningAttString.length];
        }
        //content textview
        contentTextView.attributedText = contentAttrString;
        
        idLabel.text = [NSString stringWithFormat:@"NO:%ld", (long)thread.ID];
        //set the color
        NSMutableAttributedString *uidAttrString = [[NSMutableAttributedString alloc] initWithString:@"UID:" attributes:[NSDictionary dictionaryWithObject:[UIColor colorWithRed:153.0f/255.0f green:102.0f/255.0f blue:51.0f/255.0f alpha:1.0f] forKey:NSForegroundColorAttributeName]];
        [uidAttrString appendAttributedString:thread.UID];
        //manually set the font size to avoid compatible issues in IOS6
        [uidAttrString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:10] range:NSMakeRange(0, uidAttrString.length)];
        posterLabel.attributedText = uidAttrString;
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"时间:yyyy MM-dd, HH:mm"];
        dateLabel.text = [dateFormatter stringFromDate:thread.postDateTime];
        if (thread.sage)
            [sageLabel setHidden:NO];
        else
            [sageLabel setHidden:YES];
        if (thread.lock)
            [lockLabel setHidden:NO];
        else
            [lockLabel setHidden:YES];
        
        //clickable content
        UIView *oldButton;
        while ((oldButton = [cell viewWithTag:999999]) != nil) {
            [oldButton removeFromSuperview];
        }
        for (NSString *refString in thread.replyToList) {
            NSInteger rep = refString.integerValue;
            if (rep > 0 && contentTextView) {
                NSString *quotedNumberText = [NSString stringWithFormat:@"%d", rep];
                NSRange range = [contentTextView.attributedText.string rangeOfString:quotedNumberText];
                if (range.location != NSNotFound){
                    CGRect result = [self frameOfTextRange:range inTextView:contentTextView];
                    
                    if (result.size.width > 0 && result.size.height > 0){
                        czzThreadRefButton *threadRefButton = [[czzThreadRefButton alloc] initWithFrame:CGRectMake(result.origin.x, result.origin.y + contentTextView.frame.origin.y, result.size.width, result.size.height)];
                        threadRefButton.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.1f];
                        threadRefButton.tag = 999999;
                        [threadRefButton addTarget:self action:@selector(userTapInQuotedText:) forControlEvents:UIControlEventTouchUpInside];
                        threadRefButton.threadRefNumber = rep;
                        [cell.contentView addSubview:threadRefButton];
                    }
                }
            }
        }
        
        //highlight original poster
        if (shouldHighlight && [thread.UID.string isEqualToString:parentThread.UID.string]) {
            posterLabel.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:200.0f/255.0f alpha:1.0];
            cell.contentView.backgroundColor = [UIColor clearColor];
        } else if (shouldHighlightSelectedThread && [thread.UID.string isEqualToString:shouldHighlightSelectedThread.UID.string]) {
            posterLabel.backgroundColor = [UIColor clearColor];
            cell.contentView.backgroundColor = [UIColor colorWithRed:222.0f/255.0f green:222.0f/255.0f blue:255.0f/255.0f alpha:1.0];
        }
        else {
            posterLabel.backgroundColor = [UIColor clearColor];
            cell.contentView.backgroundColor = [UIColor clearColor];
        }
    }
    return cell;
}

- (CGRect)frameOfTextRange:(NSRange)range inTextView:(UITextView *)textView {
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    CGRect rect = [textView firstRectForRange:textRange];
    return rect;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedIndex = indexPath;
    if (selectedIndex.row < threads.count){
        czzThread *selectedThread = [threads objectAtIndex:indexPath.row];
        if (selectedThread){
            [threadMenuViewController setSelectedThread:selectedThread];
        }
    } else {
        [self loadMoreThread:pageNumber];
        [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{

}

-(BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row < threads.count)
        return YES;
    return NO;
}

-(BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    return (action == @selector(copy:));
}

-(void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    if (indexPath.row >= threads.count)
        return tableView.rowHeight;

    czzThread *thread;
    @try {
        thread = [threads objectAtIndex:indexPath.row];
    }
    @catch (NSException *exception) {
        
    }
    NSMutableArray *heightArrays;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        heightArrays = heightsForRowsForHorizontal;
    } else {
        heightArrays = heightsForRows;
    }
    
    CGFloat preferHeight = tableView.rowHeight;
    if (thread){
        //retrive previously saved height
        if (indexPath.row < heightArrays.count) {
            preferHeight = [[heightArrays objectAtIndex:indexPath.row] floatValue];
        } else {
            UITextView *newHiddenTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
            newHiddenTextView.hidden = YES;
            [self.view addSubview:newHiddenTextView];
            newHiddenTextView.attributedText = thread.content;
            preferHeight = [newHiddenTextView sizeThatFits:CGSizeMake(newHiddenTextView.frame.size.width, MAXFLOAT)].height + 20;
            [newHiddenTextView removeFromSuperview];
            //height for preview image
            if (thread.thImgSrc.length != 0) {
                preferHeight += 82;
            }
            preferHeight = MAX(tableView.rowHeight, preferHeight);
            [heightArrays addObject:[NSNumber numberWithFloat:preferHeight]];
        }
    }
    return preferHeight;
}

-(void)dragOnRefreshControlAction:(id)sender{
    [self refreshThread:self];
}

#pragma mark - jump to and download controls
-(void)PromptForJumpToPage{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"跳页: %d/%d", pageNumber, ((parentThread.responseCount + 1) / 20 + 1)] message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

#pragma mark - scrollToTop and scrollToBottom 
-(void)scrollTableViewToTop {
    [threadTableView setContentOffset:CGPointMake(0.0f, -threadTableView.contentInset.top) animated:YES];
}

-(void)scrollTableViewToBottom {
    @try {
        if (threads.count > 1)
            [threadTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:threads.count inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    @catch (NSException *exception) {
        
    }
}

#pragma mark - highlight thread selected
-(void)HighlightThreadSelected:(NSNotification*)notification {
    czzThread *selectedThread = [notification.userInfo objectForKey:@"HighlightThread"];
    if (selectedThread) {
        if ([shouldHighlightSelectedThread isEqual:selectedThread]) {
            shouldHighlightSelectedThread = nil;
        }
        else
            shouldHighlightSelectedThread = selectedThread;
        [threadTableView reloadData];
    }
}

#pragma mark - search this particula user 
-(void)SearchUser:(NSNotification*)notification {
    czzThread *selectedThread = [notification.userInfo objectForKey:@"SearchUser"];
    if (selectedThread) {
        keywordToSearch = selectedThread.UID.string;
        [self performSegueWithIdentifier:@"go_search_view_segue" sender:self];
    }
}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"确定"]){
        NSInteger newPageNumber = [[[alertView textFieldAtIndex:0] text] integerValue];
        if (newPageNumber > 0){
            self.pageNumber = newPageNumber;
            //clear threads and ready to accept new threads
//            [originalThreadData removeAllObjects];
            [self.threads removeAllObjects];
            [self.threads addObject:parentThread];
            [heightsForRows removeAllObjects];
            [heightsForRowsForHorizontal removeAllObjects];
            [self.threadTableView reloadData];
            [self.refreshControl beginRefreshing];
            [self loadMoreThread:self.pageNumber];
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:[NSString stringWithFormat:@"跳到第 %d 页...", self.pageNumber]];
        } else {
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"页码无效..."];
        }
    }
}

-(void)refreshThread:(id)sender{
    [self.threads removeAllObjects];
    [self.threads addObject:parentThread];
    [heightsForRows removeAllObjects];
    [heightsForRowsForHorizontal removeAllObjects];
//    [originalThreadData removeAllObjects];
//    [originalThreadData addObject:parentThread];
    [threadTableView reloadData];
    //reset to default page number
    pageNumber = 1;
    [self loadMoreThread:pageNumber];
}

-(void)loadMoreThread:(NSInteger)pn{
    if (!pn)
        pn = pageNumber;
    if (xmlDownloader)
        [xmlDownloader stop];
    NSString *targetURLStringWithPN = [baseURLString stringByAppendingString:
                                       [NSString stringWithFormat:@"?page=%ld", (long)pn]];

    //access token for the server
    NSString *oldToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"access_token"];
    if (oldToken){
//        targetURLStringWithPN = [targetURLStringWithPN stringByAppendingFormat:@"&access_token=%@", oldToken];
    }

    xmlDownloader = [[czzXMLDownloader alloc] initWithTargetURL:[NSURL URLWithString:targetURLStringWithPN] delegate:self startNow:YES];
}

#pragma mark - UIScrollVIew delegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (onScreenCommand && threads.count > 1 && shouldDisplayQuickScrollCommand) {
        [onScreenCommand show];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
    NSArray *visibleRows = [self.tableView visibleCells];
    UITableViewCell *lastVisibleCell = [visibleRows lastObject];
    NSIndexPath *path = [self.tableView indexPathForCell:lastVisibleCell];
    if(path.row == threads.count && threads.count > 0)
    {
        CGRect lastCellRect = [threadTableView rectForRowAtIndexPath:path];
        if (lastCellRect.origin.y + lastCellRect.size.height >= threadTableView.frame.origin.y + threadTableView.frame.size.height && !xmlDownloader){
            if (((pageNumber - 1) * 20 + threads.count % 20 - 1) < parentThread.responseCount) {
                [self performSelector:@selector(loadMoreThread:) withObject:nil];
                [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:threads.count inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }
}


#pragma mark czzXMLDownloaderDelegate
-(void)downloadOf:(NSURL *)xmlURL successed:(BOOL)successed result:(NSData *)xmlData{
    [xmlDownloader stop];
    xmlDownloader = nil;
    if (successed) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            czzJSONProcessor *jsonProcessor = [czzJSONProcessor new];
            jsonProcessor.delegate = self;
            [jsonProcessor processSubThreadFromData:xmlData];
//            czzXMLProcessor *xmlProcessor = [czzXMLProcessor new];
//            xmlProcessor.delegate = self;
//            [xmlProcessor processSubThreadFromData:xmlData];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"无法下载资料，请检查网络" duration:1.2 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
            [self.refreshControl endRefreshing];
            [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
            [threadTableView reloadData];
        });
    }
}

-(void)subThreadProcessed:(NSArray *)newThread :(BOOL)success{
    if (success){
        NSArray *processedNewThread;
        //the newly downloaded thread might contain duplicate threads, therefore must compare the last chunk of current threads with the new threads, to remove any duplication
        if (threads.count > 1) {
            NSInteger lastChunkIndex = threads.count - 20;
            if (lastChunkIndex < 1)
                lastChunkIndex = 1;
            NSInteger lastChunkLength = threads.count - lastChunkIndex;
            NSRange lastChunkRange = NSMakeRange(lastChunkIndex, lastChunkLength);
            NSArray *lastChunkOfThread = [threads subarrayWithRange:lastChunkRange];
            NSMutableSet *oldThreadSet = [NSMutableSet setWithArray:lastChunkOfThread];
            [oldThreadSet addObjectsFromArray:newThread];
            [threads removeObjectsInRange:lastChunkRange];
            processedNewThread = [self sortTheGivenArray:oldThreadSet.allObjects];
        } else {
            processedNewThread = [self sortTheGivenArray:newThread];
        }
        if (shouldHideImageForThisForum) {
            for (czzThread *thread in processedNewThread) {
                thread.thImgSrc = nil;
            }
        }
        [threads addObjectsFromArray:processedNewThread];
        //increase page number if enough to fill a page of 20 threads
        if (processedNewThread.count >= 20) {
            pageNumber ++;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [threadTableView reloadData];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[czzAppDelegate sharedAppDelegate] window] makeToast:@"无法下载资料，请检查网络" duration:1.2 position:@"bottom" title:@"出错啦" image:[UIImage imageNamed:@"warning"]];
        });
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
        [[[czzAppDelegate sharedAppDelegate] window] hideToastActivity];
    });
}

//this function would convert the original threads in set to nsarray, which is more suitable to be displayed in a uitableview
-(void)convertThreadSetToThreadArray{
    //sort the array
//    NSArray *sortedArray = [self sortTheGivenArray:[originalThreadData allObjects]];
//    [threads removeAllObjects];
//    [threads addObjectsFromArray:sortedArray];
//    [threadTableView reloadData];
}

#pragma mark notification handler - image downloader
-(void)imageDownloaded:(NSNotification*)notification{
    czzImageDownloader *imgDownloader = [notification.userInfo objectForKey:@"ImageDownloader"];
    BOOL success = [[notification.userInfo objectForKey:@"Success"] boolValue];
    if (!success){
        return;
    }
    if (imgDownloader && imgDownloader.isThumbnail){
        @try {
            if ([notification.userInfo objectForKey:@"FilePath"])
                //store the given file save path
                [downloadedImages setObject:[notification.userInfo objectForKey:@"FilePath"] forKey:imgDownloader.imageURLString];
            for (NSIndexPath *displayedIndexPath in [threadTableView indexPathsForVisibleRows]) {
                if (displayedIndexPath.row >= threads.count)
                    break;
                czzThread *displayedThread = [threads objectAtIndex:displayedIndexPath.row];
                if ([displayedThread.thImgSrc.lastPathComponent isEqualToString:imgDownloader.imageURLString.lastPathComponent]){
                    [threadTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:displayedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }
    if (imgDownloader && !imgDownloader.isThumbnail){
        if (settingsCentre.userDefShouldAutoOpenImage) 
            [self showDocumentController:[notification.userInfo objectForKey:@"FilePath"]];
    }
}

#pragma mark notification handler - image downloading progress update
-(void)imageDownloaderUpdated:(NSNotification*)notification{
    czzImageDownloader *imgDownloader = [notification.userInfo objectForKey:@"ImageDownloader"];
    if (imgDownloader){
        NSInteger updateIndex = -1;
        for (czzThread *thread in threads) {
            if ([thread.imgSrc isEqualToString:imgDownloader.imageURLString]){
                updateIndex = [threads indexOfObject:thread];
                break;
            }
        }
        if (updateIndex > -1){
            UITableViewCell *cellToUpdate = [threadTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:updateIndex inSection:0]];
            DACircularProgressView *circularProgressView = (DACircularProgressView*)[cellToUpdate viewWithTag:10];
            circularProgressView.progressTintColor = [UIColor whiteColor];
            circularProgressView.trackTintColor = [UIColor grayColor];
            circularProgressView.thicknessRatio = 0.1;
            if (circularProgressView){
                if (imgDownloader.progress < 1)
                {
                    circularProgressView.hidden = NO;
                    circularProgressView.progress = imgDownloader.progress;
                } else {
                    circularProgressView.hidden = YES;
                }
                [circularProgressView setNeedsDisplay];
            }
        }
    }
}

#pragma mark sort array based on thread ID
-(NSArray*)sortTheGivenArray:(NSArray*)array{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ID" ascending:YES];
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:@[sortDescriptor]];
    /*
    NSArray *sortedArray = [array sortedArrayUsingComparator:^NSComparisonResult(id a, id b){
        czzThread *first = (czzThread*)a;
        czzThread *second = (czzThread*)b;
        return first.ID > second.ID;
    }];
     */
    return sortedArray;
}

- (IBAction)moreAction:(id)sender {
    [self.viewDeckController toggleRightViewAnimated:YES];
}

#pragma mark UITapGestureRecognizer method
//when user tapped in the ui image view, start/stop the download or show the downloaded image
- (IBAction)userTapInImage:(id)sender {
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer*)sender;
    CGPoint tapLocation = [tapGestureRecognizer locationInView:self.tableView];
    NSIndexPath *tapIndexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    czzThread *tappedThread = [threads objectAtIndex:tapIndexPath.row];
    for (NSString *file in [[czzImageCentre sharedInstance] currentLocalImages]) {
        if ([file.lastPathComponent.lowercaseString isEqualToString:tappedThread.imgSrc.lastPathComponent.lowercaseString])
        {
            [self showDocumentController:file];
            return;
        }
    }
    //Start or stop the image downloader
    if ([[czzImageCentre sharedInstance] containsImageDownloaderWithURL:tappedThread.imgSrc]){
        [[czzImageCentre sharedInstance] stopAndRemoveImageDownloaderWithURL:tappedThread.imgSrc];
        [[czzAppDelegate sharedAppDelegate] showToast:@"图片下载被终止了"];
    } else {
        BOOL completedURL = NO;
        //TODO: new server has a hardcoded URL, fix it later and allow the host to be modified remotely
        tappedThread.imgSrc = [@"http://static.acfun.mm111.net/h" stringByAppendingString:tappedThread.imgSrc];
        if ([[[NSURL URLWithString:tappedThread.imgSrc] scheme] isEqualToString:@"http"]) {
            completedURL = YES;
        }
        [[czzImageCentre sharedInstance] downloadImageWithURL:tappedThread.imgSrc isCompletedURL:completedURL];
        [[czzAppDelegate sharedAppDelegate] showToast:@"正在下载图片"];
    }
}


-(void)userTapInQuotedText:(id)sender{
    czzThreadRefButton *refButton = (czzThreadRefButton*)sender;
    NSInteger refNumber = refButton.threadRefNumber;
    for (czzThread *thread in threads) {
        if (thread.ID == refNumber){
            //record the current content offset
            threadsTableViewContentOffSet = threadTableView.contentOffset;
            //scroll to the tapped cell
            [threadTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[threads indexOfObject:thread] inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:NO];
            //retrive the tapped tableview cell from the tableview
            UITableViewCell *selectedCell = [threadTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[threads indexOfObject:thread] inSection:0]];
            UITableViewCell *cellCopy = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:selectedCell]];
            [self highlightTableViewCell:cellCopy];
            return;
        }
    }
    [[czzAppDelegate sharedAppDelegate] showToast:[NSString stringWithFormat:@"找不到帖子ID: %d, 可能不在本帖内", refNumber]];
}

#pragma mark - high light
-(void)highlightTableViewCell:(UITableViewCell*)tableviewcell{
    //disable the scrolling view
    self.threadTableView.scrollEnabled = NO;
    PartialTransparentView *containerView = [[PartialTransparentView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.threadTableView.contentSize.height) backgroundColor:[[UIColor darkGrayColor] colorWithAlphaComponent:0.7f] andTransparentRects:[NSArray arrayWithObject:[NSValue valueWithCGRect:tableviewcell.frame]]];
    
    containerView.userInteractionEnabled = YES;
    containerView.tag = OVERLAY_VIEW;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnFloatingView: )];
    //fade in effect
    containerView.alpha = 0.0f;
    [self.view addSubview:containerView];
    [UIView animateWithDuration:0.2
                     animations:^{containerView.alpha = 1.0f;}
                     completion:^(BOOL finished){[containerView addGestureRecognizer:tapRecognizer];}];
    
}

-(void)tapOnFloatingView:(UIGestureRecognizer*)gestureRecognizer{
    UIView *containerView = [[[czzAppDelegate sharedAppDelegate] window] viewWithTag:OVERLAY_VIEW];
    [UIView animateWithDuration:0.2 animations:^{
        containerView.alpha = 0.0f;
    } completion:^(BOOL finished){
        [containerView removeFromSuperview];
        //scroll back to the original position
    }];
    [threadTableView setContentOffset:threadsTableViewContentOffSet animated:YES];
    self.threadTableView.scrollEnabled = YES;
}

#pragma mark UIDocumentInteractionController delegate
-(UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
}

//show documentcontroller
-(void)showDocumentController:(NSString*)path{
    if (path){
        if (self.isViewLoaded && self.view.window) {
            if (documentInteractionController) {
                [documentInteractionController dismissPreviewAnimated:YES];
            }
            documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
            documentInteractionController.delegate = self;
            [documentInteractionController presentPreviewAnimated:YES];

        }
    }
}

#pragma mark - prepare for segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go_search_view_segue"]) {
        czzSearchViewController *searchViewController = (czzSearchViewController*)segue.destinationViewController;
        if (keywordToSearch.length > 0)
            searchViewController.predefinedSearchKeyword = keywordToSearch;
    }
}

#pragma mark - rotation change
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    UIView *containerView = [[[czzAppDelegate sharedAppDelegate] window] viewWithTag:OVERLAY_VIEW];
    //if the container view is not nil
    if (containerView)
        [self performSelector:@selector(tapOnFloatingView:) withObject:nil];
}


@end
