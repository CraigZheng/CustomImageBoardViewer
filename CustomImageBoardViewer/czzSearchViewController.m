//
//  czzSearchViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 11/07/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//
#define KEYWORD @"KEYWORD"
#define GOOGLE_SEARCH_COMMAND @"https://www.google.com.au/#q=site:h.acfun.tv+KEYWORD&sort=date:D:S:d1"
#define BING_SEARCH_COMMAND @"http://m.bing.com/search?q=site%3Ah.acfun.tv+KEYWORD&btsrc=internal"
#define AC_SEARCH_COMMAND @"http://h.acfun.tv/thread/search?key=KEYWORD"

#define USER_SELECTED_SEARCH_ENGINE @"DEFAULT_SEARCH_ENGINE"

#import "czzSearchViewController.h"
#import "czzThread.h"
#import "czzHTMLToThreadParser.h"
#import "czzThreadViewController.h"
#import "czzAppDelegate.h"
#import "czzFavouriteManagerViewController.h"
#import "Toast+UIView.h"
#import "czzHTMLParserViewController.h"
#import "czzMiniThreadViewController.h"

@interface czzSearchViewController ()<UIAlertViewDelegate, UIWebViewDelegate>
@property czzThread *selectedParentThread;
@property NSArray *searchResult;
@property UIAlertView *searchInputAlertView;
@property NSString *searchKeyword;
@property NSString *searchCommand;
@property NSURL *targetURL;
@end

@implementation czzSearchViewController
@synthesize selectedParentThread;
@synthesize searchInputAlertView;
@synthesize searchCommand;
@synthesize searchWebView;
@synthesize predefinedSearchKeyword;
@synthesize searchEngineSegmentedControl;
@synthesize searchResult;
@synthesize searchKeyword;
@synthesize targetURL;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    searchCommand = BING_SEARCH_COMMAND;
    //restore selected search engine
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    if ([userDef objectForKey:USER_SELECTED_SEARCH_ENGINE]){
        searchCommand = [userDef stringForKey:USER_SELECTED_SEARCH_ENGINE];
        if ([searchCommand isEqualToString:BING_SEARCH_COMMAND]) {
            searchEngineSegmentedControl.selectedSegmentIndex = 0;
        } else if ([searchCommand isEqualToString:GOOGLE_SEARCH_COMMAND]) {
            searchEngineSegmentedControl.selectedSegmentIndex = 1;
        } else {
            searchEngineSegmentedControl.selectedSegmentIndex = 2;
        }
    }
    
    searchInputAlertView = [[UIAlertView alloc] initWithTitle:@"关键词或号码" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    searchInputAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [searchWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://m.bing.com"]]];
    if (predefinedSearchKeyword) {
        predefinedSearchKeyword = [predefinedSearchKeyword stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[searchInputAlertView textFieldAtIndex:0] setText:predefinedSearchKeyword];
    }
    [searchInputAlertView show];

}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[czzAppDelegate sharedAppDelegate].window hideToastActivity];
}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //search
    if (alertView == searchInputAlertView) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            searchKeyword = [[[alertView textFieldAtIndex:0] text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            if (searchKeyword.integerValue > 0) {
                [[czzAppDelegate sharedAppDelegate].window makeToast:@"请稍等..."];
                [self downloadAndPrepareThreadWithID:searchKeyword.integerValue];
                
            } else {
                NSURLRequest *request = [self makeRequestWithKeyword:searchKeyword];
                if (!request) {
                    [[czzAppDelegate sharedAppDelegate].window makeToast:@"无效的关键词"];
                } else {
                    if ([searchCommand isEqualToString:AC_SEARCH_COMMAND]) {
                        [self openURLAndConvertToczzThreadFormat:request.URL];
                    } else
                        [searchWebView loadRequest:request];
                }
            }
        }
    }
}

-(void)downloadAndPrepareThreadWithID:(NSInteger)threadID {
    NSLog(@"threadID entered: %ld", (long)threadID);
    czzMiniThreadViewController *miniThreadView = [[UIStoryboard storyboardWithName:@"MiniThreadView" bundle:nil] instantiateInitialViewController];
    miniThreadView.threadID = threadID;
    [self.navigationController pushViewController:miniThreadView animated:YES];
}

-(NSURLRequest*)makeRequestWithKeyword:(NSString*)keyword {
    if (keyword.length == 0) {
        return nil;
    }
    NSString *searchURL = [searchCommand stringByReplacingOccurrencesOfString:KEYWORD withString:keyword];
    return [NSURLRequest requestWithURL:[NSURL URLWithString:searchURL]];
}
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"go_html_parser_view_controller"]) {
        czzHTMLParserViewController *parserViewController = (czzHTMLParserViewController *)segue.destinationViewController;
        if ([parserViewController isKindOfClass:[czzHTMLParserViewController class]]) {
            parserViewController.targetURL = targetURL;
            parserViewController.highlightKeyword = searchKeyword;
        }
    } else if ([segue.identifier isEqualToString:@"go_thread_view_segue"]) {
        czzThreadViewController *threadViewController = (czzThreadViewController*) segue.destinationViewController;
        threadViewController.parentThread = selectedParentThread;
    }
}

-(void)openURLAndConvertToczzThreadFormat:(NSURL*)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[czzAppDelegate sharedAppDelegate].window makeToastActivity];
    });
    if ([url.absoluteString rangeOfString:@"?ph"].location != NSNotFound) {
        NSString *urlString = url.absoluteString;
        urlString = [urlString substringToIndex:[urlString rangeOfString:@"?ph"].location];
        //remove "pn" - page number parameter
        url = [NSURL URLWithString:urlString];
    }
    //load html in background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *htmlData = [NSData dataWithContentsOfURL:url];
        if (htmlData) {
            @try {
                NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
                czzHTMLToThreadParser *htmlParser = [czzHTMLToThreadParser new];
                [htmlParser parse:htmlString];
                NSArray *threads = htmlParser.parsedThreads;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (threads.count > 0) {
                        selectedParentThread = [threads firstObject];
                        searchResult = threads;
                        // if viewController is visible
                        if (self.isViewLoaded && self.view.window) {
                            if ([searchCommand isEqualToString:AC_SEARCH_COMMAND]) {
                                [self performSegueWithIdentifier:@"go_favourite_view_segue" sender:self];
                            } else
                                [self performSegueWithIdentifier:@"go_thread_view_segue" sender:self];

                        }
                    } else {
                        [[czzAppDelegate sharedAppDelegate].window makeToast:@"无法打开这个链接" duration:2.0 position:@"bottom" image:[UIImage imageNamed:@"warning.png"]];
                    }
                });

            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[czzAppDelegate sharedAppDelegate].window makeToast:@"无法打开这个链接" duration:2.0 position:@"bottom" image:[UIImage imageNamed:@"warning.png"]];
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[czzAppDelegate sharedAppDelegate].window hideToastActivity];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[czzAppDelegate sharedAppDelegate].window makeToast:@"无法找到有效资料" duration:2.0 position:@"bottom" image:[UIImage imageNamed:@"warning.png"]];
                [[czzAppDelegate sharedAppDelegate].window hideToastActivity];
            });
        }
    });

}

#pragma mark - UIWebViewDelegate
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[czzAppDelegate sharedAppDelegate].window hideToastActivity];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"should navigate to URL: %@", request.URL.absoluteString);
    //user tapped on link
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if ([request.URL.absoluteString rangeOfString:@"h.acfun.tv"].location == NSNotFound) {
            [[czzAppDelegate sharedAppDelegate].window makeToast:@"这个App只支持AC匿名版的链接" duration:2.0 position:@"center" image:[UIImage imageNamed:@"warning.png"]];
            return NO;
        } else {
            if ([request.URL.host rangeOfString:@"acfun"].location != NSNotFound) {
                NSString *acURL = [[request.URL.absoluteString componentsSeparatedByString:@"?"].firstObject stringByReplacingOccurrencesOfString:@"m/" withString:@""]; //only the first few components are useful, the host and the thread id
                targetURL = [NSURL URLWithString:acURL];
                [self performSegueWithIdentifier:@"go_html_parser_view_controller" sender:self];
                return NO;
            }
        }
        return YES;
    }
    return YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [[czzAppDelegate sharedAppDelegate].window hideToastActivity];
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    [[czzAppDelegate sharedAppDelegate].window makeToastActivity];
}

- (IBAction)againAction:(id)sender {
    if (!searchInputAlertView.isVisible) {
        [searchInputAlertView show];
    }
}

- (IBAction)segmentControlChanged:(id)sender {
    UISegmentedControl *segmentedControl = (UISegmentedControl*)sender;
    if (segmentedControl.selectedSegmentIndex == 0) {
        searchCommand = BING_SEARCH_COMMAND;
    } else if (segmentedControl.selectedSegmentIndex == 1)
    {
        searchCommand = GOOGLE_SEARCH_COMMAND;
    }
    else if (segmentedControl.selectedSegmentIndex ==2) {
        searchCommand = AC_SEARCH_COMMAND;
    }
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setObject:searchCommand forKey:USER_SELECTED_SEARCH_ENGINE];
    [userDef synchronize];
}
@end
