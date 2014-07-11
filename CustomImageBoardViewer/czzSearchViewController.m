//
//  czzSearchViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 11/07/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//
#define KEYWORD @"KEYWORD"
#define GOOGLE_SEARCH_COMMAND @"https://www.google.com.au/#q=site:h.acfun.tv+KEYWORD"
#define BING_SEARCH_COMMAND @"http://m.bing.com/search?q=site%3Ah.acfun.tv+KEYWORD&btsrc=internal"

#define USER_SELECTED_SEARCH_ENGINE @"DEFAULT_SEARCH_ENGINE"

#import "czzSearchViewController.h"
#import "czzThread.h"
#import "czzHTMLToThreadParser.h"
#import "czzThreadViewController.h"
#import "czzAppDelegate.h"
#import "Toast+UIView.h"

@interface czzSearchViewController ()<UIAlertViewDelegate, UIWebViewDelegate>
@property czzThread *selectedParentThread;
@property UIAlertView *searchInputAlertView;
@property NSString *searchCommand;
@end

@implementation czzSearchViewController
@synthesize selectedParentThread;
@synthesize searchInputAlertView;
@synthesize searchCommand;
@synthesize searchWebView;
@synthesize predefinedSearchKeyword;
@synthesize searchEngineSegmentedControl;

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
        } else {
            searchEngineSegmentedControl.selectedSegmentIndex = 1;
        }
    }
    
    searchInputAlertView = [[UIAlertView alloc] initWithTitle:@"关键词" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
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
    if ([alertView.title isEqualToString:@"关键词"]) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            NSURLRequest *request = [self makeRequestWithKeyword:[[[alertView textFieldAtIndex:0] text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            if (!request) {
                [[czzAppDelegate sharedAppDelegate].window makeToast:@"无效的搜索"];
            } else
                [searchWebView loadRequest:request];
        }
    }
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
    if ([segue.identifier isEqualToString:@"go_thread_view_segue"]) {
        czzThreadViewController *threadViewController = (czzThreadViewController*)segue.destinationViewController;
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
                        [self performSegueWithIdentifier:@"go_thread_view_segue" sender:self];
                    } else {
                        [[czzAppDelegate sharedAppDelegate].window makeToast:@"无法打开这个链接" duration:2.0 position:@"centre" image:[UIImage imageNamed:@"warning.png"]];
                    }
                });

            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[czzAppDelegate sharedAppDelegate].window makeToast:@"无法打开这个链接" duration:2.0 position:@"centre" image:[UIImage imageNamed:@"warning.png"]];
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
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
                [self openURLAndConvertToczzThreadFormat:request.URL];
                return NO;
            }
        }
        return YES;
    }
//    } else if (navigationType == UIWebViewNavigationTypeOther && [request.URL.absoluteString rangeOfString:@"h.acfun.tv"].location != NSNotFound){
//        //load the given url and parse it
//    }
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
    } else
    {
        searchCommand = GOOGLE_SEARCH_COMMAND;
    }
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setObject:searchCommand forKey:USER_SELECTED_SEARCH_ENGINE];
    [userDef synchronize];
}
@end