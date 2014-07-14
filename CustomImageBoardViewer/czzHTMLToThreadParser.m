//
//  czzHTMLToThreadParser.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 11/07/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define DEBUG_URL @"http://h.acfun.tv/m/t/1426591?r=1430861#1430861"

#import "czzHTMLToThreadParser.h"
#import "czzThread.h"
#import "NSString+HTML.h"

@interface czzHTMLToThreadParser ()
@property NSString *htmlContent;
@end

@implementation czzHTMLToThreadParser
@synthesize htmlContent;
@synthesize parsedThreads;

-(void)parse:(NSString*)htmlString {
    htmlContent = htmlString;
    NSDate *startTime = [NSDate new];
    [self scanHTML:htmlContent];
    NSLog(@"took %f second to render", [[NSDate new] timeIntervalSinceDate:startTime]);
}

-(void)scanHTML:(NSString*)htmlString {
    NSRange r;
    czzThread *newThread = [czzThread new];
    NSMutableArray *threads = [NSMutableArray new];
    NSMutableArray *uidArray = [NSMutableArray new];
    while ((r = [htmlString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
        @try {
            NSRange endTagRange;
            NSString *tagString = [htmlString substringWithRange:r];
            //title and author
            if ([tagString rangeOfString:@"<font"].location != NSNotFound && (endTagRange = [htmlString rangeOfString:@"<+/[^>]+>" options:NSRegularExpressionSearch range:NSMakeRange(r.location + r.length, htmlString.length - r.length - r.location)]).location != NSNotFound) {
                NSRange textRange = NSMakeRange(r.location + r.length, endTagRange.location - r.location - r.length);
                NSString *textWithinTags = [htmlString substringWithRange:textRange];
                textWithinTags = [self removeHTMLTags:textWithinTags];
                if ([tagString rangeOfString:@"cc1105"].location != NSNotFound) {
                    newThread.title = textWithinTags;
                }
                else if ([tagString rangeOfString:@"117743"].location != NSNotFound) {
                    newThread.name = textWithinTags;
                }
            }
            //ID
            if ([tagString rangeOfString:@"rel="].location != NSNotFound && (endTagRange = [htmlString rangeOfString:@"<+/[^>]+>" options:NSRegularExpressionSearch range:NSMakeRange(r.location + r.length, htmlString.length - r.length - r.location)]).location != NSNotFound) {
                NSRange textRange = NSMakeRange(r.location + r.length, endTagRange.location - r.location - r.length);
                NSString *textWithinTags = [htmlString substringWithRange:textRange];
                textWithinTags = [self removeHTMLTags:textWithinTags];
                NSRange noRange;
                if ((noRange = [textWithinTags rangeOfString:@"No."]).location != NSNotFound) {
                    NSString *idString = [[textWithinTags componentsSeparatedByCharactersInSet:
                                            [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                           componentsJoinedByString:@""];
                    newThread.ID = idString.integerValue;
                    
                    htmlString = [htmlString stringByReplacingCharactersInRange:NSMakeRange(noRange.location + noRange.length, 10) withString:@""];
                }
                
            }
            //UID, these are plain text, have no tags
            //TODO: time
            NSRange idRange;
            if ((idRange = [htmlString rangeOfString:@"ID:"]).location != NSNotFound) {
                NSString *uidString = [htmlString substringWithRange:NSMakeRange(idRange.location + idRange.length, 8)];
                [uidArray addObject:[[czzThread new] renderHTMLToAttributedString:uidString]];
                htmlString = [htmlString stringByReplacingCharactersInRange:idRange withString:@""];
            }
            //         2014/7/10 13:26:52 ID:GcrJTfS7 [
            //the images
            if ([tagString rangeOfString:@"<a href"].location != NSNotFound && (endTagRange = [htmlString rangeOfString:@"<+/[^>]+>" options:NSRegularExpressionSearch range:NSMakeRange(r.location + r.length, htmlString.length - r.length - r.location)]).location != NSNotFound && [tagString rangeOfString:@"title" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                NSRange textRange = NSMakeRange(r.location + r.length, endTagRange.location - r.location - r.length);
                NSString *textWithinTags = [htmlString substringWithRange:textRange];
                if ([textWithinTags rangeOfString:@"<img"].location != NSNotFound) {
                    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
                    NSArray *matches = [linkDetector matchesInString:tagString
                                                             options:0
                                                               range:NSMakeRange(0, tagString.length)];
                    if (matches.count > 0){
                        for (NSTextCheckingResult *match in matches) {
                            if ([match resultType] == NSTextCheckingTypeLink) {
                                NSURL *url = [match URL];
                                newThread.imgSrc = url.absoluteString;
                                newThread.thImgSrc = url.absoluteString;
                            }
                        }
                    }

                }
            }
            //content
            if ([tagString rangeOfString:@"<blockquote"].location != NSNotFound && (endTagRange = [htmlString rangeOfString:@"<+/+b+[^>]+>" options:NSRegularExpressionSearch range:NSMakeRange(r.location + r.length, htmlString.length - r.length - r.location)]).location != NSNotFound) {
                NSRange textRange = NSMakeRange(r.location + r.length, endTagRange.location - r.location - r.length);
                NSString *textWithinTags = [htmlString substringWithRange:textRange];
                //remove duplicate white space
                while ([textWithinTags rangeOfString:@"  "].location != NSNotFound) {
                    textWithinTags = [textWithinTags stringByReplacingOccurrencesOfString:@"  " withString:@" "];
                }
                textWithinTags = [textWithinTags stringByRemovingNewLinesAndWhitespace];
//                textWithinTags = [self removeHTMLTags:textWithinTags];
                newThread.content = [[czzThread new] renderHTMLToAttributedString:textWithinTags];
            }
            //this thread is ready, initiate next iteration
            if (newThread.content != nil) {
                //            break;
                [threads addObject:newThread];
                newThread = [czzThread new];
            }
            htmlString = [htmlString stringByReplacingCharactersInRange:r withString:@""];
            
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }
    //assign UID
    for (NSInteger i = 0; i < uidArray.count; i++) {
        if (i < threads.count) {
            czzThread *tmpThread = [threads objectAtIndex:i];
            tmpThread.UID = [uidArray objectAtIndex:i];
        }
    }
    parsedThreads = threads;
}

-(NSString*)removeHTMLTags:(NSString*)stringToProcess {
    NSRange r;
    while ((r = [stringToProcess rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
        stringToProcess = [stringToProcess stringByReplacingCharactersInRange:r withString:@""];
    }
    return stringToProcess;
}
@end
