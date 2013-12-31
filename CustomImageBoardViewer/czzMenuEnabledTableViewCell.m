//
//  czzMenuEnabledTableViewCell.m
//  CustomImageBoardViewer
//
//  Created by Craig on 31/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzMenuEnabledTableViewCell.h"
#import "czzPostViewController.h"
#import "czzAppDelegate.h"

@implementation czzMenuEnabledTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code


    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender{
    return (action == @selector(menuActionReply:) ||
            action == @selector(menuActionCopy:));
}

-(BOOL)canBecomeFirstResponder{
    return YES;
}

#pragma mark - custom menu action
-(void)menuActionCopy:(id)sender{
    [[UIPasteboard generalPasteboard] setString:self.myThread.content.string];
    [[czzAppDelegate sharedAppDelegate] showToast:@"内容已复制"];
}

-(void)menuActionReply:(id)sender{
    NSLog(@"reply: %@", sender);
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.myThread forKey:@"ReplyToThread"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReplyAction" object:Nil userInfo:userInfo];
}
@end
