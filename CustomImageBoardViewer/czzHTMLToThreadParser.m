//
//  czzHTMLToThreadParser.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 11/07/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#define DEBUG_URL @"http://h.acfun.tv/t/3892886"
#import "czzHTMLToThreadParser.h"
#import "czzThread.h"

@interface czzHTMLToThreadParser ()
@property NSString *htmlContent;
@end

@implementation czzHTMLToThreadParser
@synthesize htmlContent;
-(id)init {
    self = [super init];
    if (self) {
        [self parse];
    }
    return self;
}

-(void)parse {
    htmlContent = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:DEBUG_URL]] encoding:NSUTF8StringEncoding];
    [self scanHTML:htmlContent];
}

-(void)scanHTML:(NSString*)htmlString {
    NSRange r;
    czzThread *newThread = [czzThread new];
    NSMutableArray *threads = [NSMutableArray new];
    while ((r = [htmlString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
        @try {
            NSRange endTagRange;
            NSString *tagString = [htmlString substringWithRange:r];
            //title and author
            if ([tagString rangeOfString:@"<font"].location != NSNotFound && (endTagRange = [htmlString rangeOfString:@"<+/[^>]+>" options:NSRegularExpressionSearch range:NSMakeRange(r.location + r.length, htmlString.length - r.length - r.location)]).location != NSNotFound) {
                NSRange textRange = NSMakeRange(r.location + r.length, endTagRange.location - r.location - r.length);
                NSString *textWithinTags = [htmlString substringWithRange:textRange];
                textWithinTags = [self removeHTMLTags:textWithinTags];
                NSLog(@"font tag text: %@", textWithinTags);
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
                NSLog(@"ID text: %@", textWithinTags);
                NSInteger myId;
                NSRange noRange;
                if ((noRange = [textWithinTags rangeOfString:@"No."]).location != NSNotFound) {
                    NSString *noString = [htmlString substringWithRange:NSMakeRange(noRange.location + noRange.length, 10)];
                    NSInteger myId = noString.integerValue;
                    newThread.ID = myId;
                    htmlString = [htmlString stringByReplacingCharactersInRange:NSMakeRange(noRange.location + noRange.length, 10) withString:@""];
                }
//                NSScanner *scanner = [NSScanner scannerWithString:textWithinTags];
//                if ([scanner scanInteger: &myId])
//                    newThread.ID = myId;
                
            }
            //TODO; UID and time
            NSRange idRange;
            if ((idRange = [htmlString rangeOfString:@"ID:"]).location != NSNotFound) {
                newThread.UID = [newThread renderHTMLToAttributedString:[htmlString substringWithRange:NSMakeRange(idRange.location + idRange.length, 8)]];
                htmlString = [htmlString stringByReplacingCharactersInRange:idRange withString:@""];
            }
            //         2014/7/10 13:26:52 ID:GcrJTfS7 [
            //the images
            if ([tagString rangeOfString:@"<img"].location != NSNotFound && (endTagRange = [htmlString rangeOfString:@"<+/[^>]+>" options:NSRegularExpressionSearch range:NSMakeRange(r.location + r.length, htmlString.length - r.length - r.location)]).location != NSNotFound) {
                NSRange textRange = NSMakeRange(r.location + r.length, endTagRange.location - r.location - r.length);
                NSString *textWithinTags = [htmlString substringWithRange:textRange];
                textWithinTags = [self removeHTMLTags:textWithinTags];
                newThread.thImgSrc = textWithinTags;
                newThread.imgSrc = [textWithinTags stringByReplacingOccurrencesOfString:@"/Th" withString:@""]; //hardcoded, but better than leave it empty
            }
            //content
            if ([tagString rangeOfString:@"<blockquote"].location != NSNotFound && (endTagRange = [htmlString rangeOfString:@"<+/[^>]+>" options:NSRegularExpressionSearch range:NSMakeRange(r.location + r.length, htmlString.length - r.length - r.location)]).location != NSNotFound) {
                NSRange textRange = NSMakeRange(r.location + r.length, endTagRange.location - r.location - r.length);
                NSString *textWithinTags = [htmlString substringWithRange:textRange];
                textWithinTags = [self removeHTMLTags:textWithinTags];
                newThread.content = [newThread renderHTMLToAttributedString:textWithinTags];
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
//    NSLog(@"%@", newThread);
    NSLog(@"%@", threads);
}

-(NSString*)removeHTMLTags:(NSString*)stringToProcess {
    NSRange r;
    while ((r = [stringToProcess rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
        stringToProcess = [stringToProcess stringByReplacingCharactersInRange:r withString:@""];
    }
    return stringToProcess;
}
@end
