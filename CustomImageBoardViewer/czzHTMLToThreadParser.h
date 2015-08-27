//
//  czzHTMLToThreadParser.h
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 11/07/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@class czzHTMLToThreadParser;
@protocol HTMLParserDelegate <NSObject>
-(void)updated:(czzHTMLToThreadParser*)parser currentContent:(NSString*)html;
@end

@interface czzHTMLToThreadParser : NSObject
@property NSArray *parsedThreads;
@property NSString *htmlContent;
@property (weak, nonatomic) id<HTMLParserDelegate> delegate;

-(void)parse:(NSString*)htmlString;
@end
