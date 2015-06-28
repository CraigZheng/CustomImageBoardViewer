//
//  czzHTMLParserViewController.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 1/10/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import "czzHTMLParserViewController.h"
#import "czzThread.h"
#import "czzHTMLToThreadParser.h"
#import "czzThreadViewController.h"
#import "czzAppDelegate.h"
#import "Toast+UIView.h"

@interface czzHTMLParserViewController () <HTMLParserDelegate>
@property czzThread *parsedThread;
@end

@implementation czzHTMLParserViewController
@synthesize targetURL;
@synthesize parsedThread;
@synthesize highlightKeyword;
@synthesize contentTextView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"HTML解析器";
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (targetURL) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self openURLAndConvertToczzThreadFormat:targetURL];
        });
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [AppDelegate.window hideToastActivity];
}

-(void)openURLAndConvertToczzThreadFormat:(NSURL*)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        contentTextView.text = @"";
        [AppDelegate.window makeToastActivity];
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    contentTextView.text = htmlString;
                });
                czzHTMLToThreadParser *htmlParser = [czzHTMLToThreadParser new];
                htmlParser.delegate = self;
                [htmlParser parse:htmlString];
                NSArray *threads = htmlParser.parsedThreads;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (threads.count > 0) {
                        parsedThread = [threads firstObject];
                        // if viewController is visible
                        if (self.isViewLoaded && self.view.window) {
                            [self presentThreadViewControllerWithParsedThread];
                        }
                    } else {
                        [AppDelegate.window makeToast:@"无法打开这个链接" duration:2.0 position:@"bottom" image:[UIImage imageNamed:@"warning.png"]];
                    }
                });
                
            }
            @catch (NSException *exception) {
                DLog(@"%@", exception);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [AppDelegate.window makeToast:@"无法打开这个链接" duration:2.0 position:@"bottom" image:[UIImage imageNamed:@"warning.png"]];
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [AppDelegate.window hideToastActivity];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [AppDelegate.window makeToast:@"无法找到有效资料" duration:2.0 position:@"bottom" image:[UIImage imageNamed:@"warning.png"]];
                [AppDelegate.window hideToastActivity];
            });
        }
    });
    
}

-(void)presentThreadViewControllerWithParsedThread {
    if (!parsedThread) {
        return;
    }
    
    czzThreadViewController *threadViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"czz_thread_view_controller"];
//    threadViewController.parentThread = parsedThread;
    if (highlightKeyword.length > 0)
        threadViewController.shouldHighlightSelectedUser = highlightKeyword;
    
    NSMutableArray *currentViewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    [currentViewControllers removeLastObject];
    [currentViewControllers addObject:threadViewController];
    [self.navigationController setViewControllers:currentViewControllers animated:YES];
}

#pragma mark - HTMLParserDelegate
-(void)updated:(czzHTMLToThreadParser*)parser currentContent:(NSString *)html{
    dispatch_async(dispatch_get_main_queue(), ^{
        contentTextView.text = html;
        int percent = (int)(((parser.htmlContent.length - html.length) / (float)(parser.htmlContent.length)) * 100.0);
        self.title = [NSString stringWithFormat:@"HTML解析器: %d%%", percent];
    });
}
@end
