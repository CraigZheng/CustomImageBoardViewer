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
    while ((r = [htmlString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
        NSRange endTagRange;
        NSString *tagString = [htmlString substringWithRange:r];
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
        if ([tagString rangeOfString:@"<class=\"r\""].location != NSNotFound && (endTagRange = [htmlString rangeOfString:@"<+/[^>]+>" options:NSRegularExpressionSearch range:NSMakeRange(r.location + r.length, htmlString.length - r.length - r.location)]).location != NSNotFound) {
            NSRange textRange = NSMakeRange(r.location + r.length, endTagRange.location - r.location - r.length);
            NSString *textWithinTags = [htmlString substringWithRange:textRange];
            textWithinTags = [self removeHTMLTags:textWithinTags];
            NSLog(@"ID text: %@", textWithinTags);
            newThread.ID = textWithinTags.integerValue;
        }
        if ([tagString rangeOfString:@"<img"].location != NSNotFound && (endTagRange = [htmlString rangeOfString:@"<+/[^>]+>" options:NSRegularExpressionSearch range:NSMakeRange(r.location + r.length, htmlString.length - r.length - r.location)]).location != NSNotFound) {
            NSRange textRange = NSMakeRange(r.location + r.length, endTagRange.location - r.location - r.length);
            NSString *textWithinTags = [htmlString substringWithRange:textRange];
            textWithinTags = [self removeHTMLTags:textWithinTags];
            newThread.thImgSrc = textWithinTags;
            newThread.imgSrc = textWithinTags; //just to not let it be empty
        }
        
        if ([tagString rangeOfString:@"<blockquote"].location != NSNotFound && (endTagRange = [htmlString rangeOfString:@"<+/[^>]+>" options:NSRegularExpressionSearch range:NSMakeRange(r.location + r.length, htmlString.length - r.length - r.location)]).location != NSNotFound) {
            NSRange textRange = NSMakeRange(r.location + r.length, endTagRange.location - r.location - r.length);
            NSString *textWithinTags = [htmlString substringWithRange:textRange];
            textWithinTags = [self removeHTMLTags:textWithinTags];
            newThread.content = [[NSAttributedString alloc] initWithString:textWithinTags];
        }
        if (newThread.content != nil) {
            break;
        }
        htmlString = [htmlString stringByReplacingCharactersInRange:r withString:@""];
    }
    NSLog(@"%@", newThread);
}

-(NSString*)removeHTMLTags:(NSString*)stringToProcess {
    NSRange r;
    while ((r = [stringToProcess rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
        stringToProcess = [stringToProcess stringByReplacingCharactersInRange:r withString:@""];
    }
    return stringToProcess;
}
@end
