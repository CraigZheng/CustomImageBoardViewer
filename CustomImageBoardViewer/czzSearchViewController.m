//
//  czzSearchViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 11/07/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//
#define KEYWORD @"KEYWORD"
#define A_ISLE_HOST @"A_ISLE_HOST"
#define GOOGLE_SEARCH_COMMAND @"https://www.google.com.au/#q=site:A_ISLE_HOST+KEYWORD&sort=date:D:S:d1"
#define BING_SEARCH_COMMAND @"http://m.bing.com/search?q=site%3AA_ISLE_HOST+KEYWORD&btsrc=internal"
#define AC_SEARCH_COMMAND @"http://h.acfun.tv/thread/search?key=KEYWORD"

#define USER_SELECTED_SEARCH_ENGINE @"DEFAULT_SEARCH_ENGINE"

#import "czzSearchViewController.h"
#import "czzThread.h"
#import "czzThreadViewController.h"
#import "czzAppDelegate.h"
#import "czzFavouriteManagerViewController.h"
#import "Toast+UIView.h"
#import "czzMiniThreadViewController.h"
#import "czzSettingsCentre.h"
#import "czzNavigationController.h"

@interface czzSearchViewController ()<UIAlertViewDelegate, UIWebViewDelegate>
@property czzThread *selectedParentThread;
@property NSArray *searchResult;
@property UIAlertView *searchInputAlertView;
@property (strong, nonatomic) NSString *searchKeyword;
@property (strong, nonatomic) NSString *selectedSearchEngine;
@property NSURL *targetURL;
@property czzMiniThreadViewController *miniThreadView;
@property GSIndeterminateProgressView *progressView;
@end

@implementation czzSearchViewController
@synthesize selectedParentThread;
@synthesize searchInputAlertView;
@synthesize selectedSearchEngine;
@synthesize searchWebView;
@synthesize predefinedSearchKeyword;
@synthesize searchEngineSegmentedControl;
@synthesize searchResult;
@synthesize searchKeyword;
@synthesize targetURL;
@synthesize progressView;
@synthesize miniThreadView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    selectedSearchEngine = BING_SEARCH_COMMAND;
    //restore selected search engine
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    if ([userDef objectForKey:USER_SELECTED_SEARCH_ENGINE]){
        selectedSearchEngine = [userDef stringForKey:USER_SELECTED_SEARCH_ENGINE];
        if ([selectedSearchEngine isEqualToString:BING_SEARCH_COMMAND]) {
            searchEngineSegmentedControl.selectedSegmentIndex = 0;
        } else if ([selectedSearchEngine isEqualToString:GOOGLE_SEARCH_COMMAND]) {
            searchEngineSegmentedControl.selectedSegmentIndex = 1;
        } else {
            searchEngineSegmentedControl.selectedSegmentIndex = 2;
        }
    }
    
    //progress view
    progressView = [(czzNavigationController*)self.navigationController progressView];
    
    searchInputAlertView = [[UIAlertView alloc] initWithTitle:@"关键词或号码" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    searchInputAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textInputField = [searchInputAlertView textFieldAtIndex:0];
    if (textInputField)
    {
        textInputField.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    [searchWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://m.bing.com"]]];
    if (predefinedSearchKeyword) {
        predefinedSearchKeyword = [predefinedSearchKeyword stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[searchInputAlertView textFieldAtIndex:0] setText:predefinedSearchKeyword];
    }
    [searchInputAlertView show];

}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Google Analytic integration
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass(self.class)];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [AppDelegate.window hideToastActivity];
}

/*
 check numeric string
 */
-(BOOL)isNumeric:(NSString*)inputString {
    BOOL valid;
    NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString:inputString];
    valid = [alphaNums isSupersetOfSet:inStringSet];
    return valid;
}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //search
    if (alertView == searchInputAlertView) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            searchKeyword = [[[alertView textFieldAtIndex:0] text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            if ([self isNumeric:searchKeyword]) {
                [AppDelegate.window makeToast:@"请稍等..."];
                [self downloadAndPrepareThreadWithID:searchKeyword.integerValue];
                
            } else {
                NSURLRequest *request = [self makeRequestWithKeyword:searchKeyword];
                if (!request) {
                    [AppDelegate.window makeToast:@"无效的关键词"];
                } else {
                    [searchWebView loadRequest:request];
                }
            }
        }
    }
}

-(void)downloadAndPrepareThreadWithID:(NSInteger)threadID {
    czzThread *dummpyParentThread = [czzThread new];
    dummpyParentThread.ID = threadID;
    czzThreadViewManager *threadViewManager = [[czzThreadViewManager alloc] initWithParentThread:dummpyParentThread andForum:nil];
    czzThreadViewController *threadViewController = [[UIStoryboard storyboardWithName:THREAD_VIEW_CONTROLLER_STORYBOARD_NAME bundle:nil] instantiateViewControllerWithIdentifier:THREAD_VIEW_CONTROLLER_ID];
    threadViewController.threadViewManager = threadViewManager;
    [NavigationManager pushViewController:threadViewController animated:YES];
//    miniThreadView = [[UIStoryboard storyboardWithName:@"MiniThreadView" bundle:nil] instantiateInitialViewController];
//    miniThreadView.delegate = self;
//    miniThreadView.threadID = threadID;
}

-(NSURLRequest*)makeRequestWithKeyword:(NSString*)keyword {
    if (keyword.length == 0) {
        return nil;
    }
    NSURL *aIsleHostURL = [NSURL URLWithString:[settingCentre a_isle_host]];
    NSString *searchURL = [[selectedSearchEngine stringByReplacingOccurrencesOfString:A_ISLE_HOST withString:[aIsleHostURL host]] stringByReplacingOccurrencesOfString:KEYWORD withString:keyword];
    DDLogDebug(@"search: %@", searchURL);
    return [NSURLRequest requestWithURL:[NSURL URLWithString:searchURL]];
}
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:showThreadViewSegueIdentifier]) {
        czzThreadViewController *threadViewController = (czzThreadViewController*) segue.destinationViewController;
        czzThreadViewManager *threadViewManager = [[czzThreadViewManager alloc] initWithParentThread:selectedParentThread andForum:[czzForum new]];
        threadViewController.threadViewManager = threadViewManager;
    }
}

#pragma mark - UIWebViewDelegate
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [AppDelegate.window hideToastActivity];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    DDLogDebug(@"should navigate to URL: %@", request.URL.absoluteString);
    //user tapped on link
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if ([request.URL.absoluteString rangeOfString:[settingCentre a_isle_host]].location == NSNotFound) {
            [AppDelegate.window makeToast:@"这个App只支持AC匿名版的链接" duration:2.0 position:@"center" image:[UIImage imageNamed:@"warning.png"]];
            return NO;
        } else {
            //get final URL
            NSString *acURL = [[request.URL.absoluteString componentsSeparatedByString:@"?"].firstObject stringByDeletingPathExtension]; //only the first few components are useful, the host and the thread id
            targetURL = [NSURL URLWithString:acURL];
            [AppDelegate.window makeToast:@"请稍等..."];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *data = nil;
                
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:targetURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:4];
                NSURLResponse *response;
                NSError *error;
                data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                NSURL *LastURL = [response URL];
                
                //from final URL get thread ID
                NSString *threadID = [LastURL.absoluteString componentsSeparatedByString:@"/"].lastObject;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self downloadAndPrepareThreadWithID:threadID.integerValue];
                });
            });
            
            return NO;

        }
        return NO;
    }
    return YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [progressView stopAnimating];
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    [progressView startAnimating];
}

- (IBAction)againAction:(id)sender {
    if (!searchInputAlertView.isVisible) {
        [searchInputAlertView show];
    }
}

- (IBAction)segmentControlChanged:(id)sender {
    UISegmentedControl *segmentedControl = (UISegmentedControl*)sender;
    if (segmentedControl.selectedSegmentIndex == 0) {
        selectedSearchEngine = BING_SEARCH_COMMAND;
    } else if (segmentedControl.selectedSegmentIndex == 1)
    {
        selectedSearchEngine = GOOGLE_SEARCH_COMMAND;
    }
    else if (segmentedControl.selectedSegmentIndex ==2) {
        selectedSearchEngine = AC_SEARCH_COMMAND;
    }
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setObject:selectedSearchEngine forKey:USER_SELECTED_SEARCH_ENGINE];
    [userDef synchronize];
}


@end
