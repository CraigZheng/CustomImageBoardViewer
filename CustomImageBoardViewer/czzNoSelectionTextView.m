//
//  czzNoSelectionTextView.m
//  CustomImageBoardViewer
//
//  Created by Craig on 31/12/2013.
//  Copyright (c) 2013 Craig. All rights reserved.
//

#import "czzNoSelectionTextView.h"

@implementation czzNoSelectionTextView

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return NO;
}

- (UIMenu *)editMenuForTextInRange:(NSRange)range suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions API_AVAILABLE(ios(16.0)) {
    return [UIMenu menuWithChildren:@[]];
}

/// Only claim touches that land on a link; everything else falls through to the cell/table.
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (![super pointInside:point withEvent:event]) {
        return NO;
    }
    return [self containsLinkAtPoint:point];
}

/// Uses UITextInput APIs only — avoids accessing layoutManager/textStorage, which forces TextKit 1 mode.
- (BOOL)containsLinkAtPoint:(CGPoint)point {
    NSAttributedString *text = self.attributedText;
    if (text.length == 0) {
        return NO;
    }

    UITextPosition *position = [self closestPositionToPoint:point];
    if (!position) {
        return NO;
    }

    UITextPosition *next = [self positionFromPosition:position offset:1] ?: position;
    UITextRange *characterRange = [self textRangeFromPosition:position toPosition:next];
    CGRect glyphRect = [self firstRectForRange:characterRange];
    if (CGRectIsNull(glyphRect) || CGRectIsEmpty(glyphRect)) {
        glyphRect = [self caretRectForPosition:position];
    }
    if (!CGRectContainsPoint(CGRectInset(glyphRect, -4.0, -4.0), point)) {
        return NO;
    }

    NSInteger index = [self offsetFromPosition:self.beginningOfDocument toPosition:position];
    if (index < 0 || index >= (NSInteger)text.length) {
        return NO;
    }

    return [text attribute:NSLinkAttributeName atIndex:(NSUInteger)index effectiveRange:NULL] != nil;
}

@end
