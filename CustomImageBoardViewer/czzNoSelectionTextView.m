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

- (BOOL)containsLinkAtPoint:(CGPoint)point {
    if (self.textStorage.length == 0) {
        return NO;
    }

    CGPoint location = CGPointMake(point.x - self.textContainerInset.left,
                                   point.y - self.textContainerInset.top);
    location.x -= self.textContainer.lineFragmentPadding;

    NSLayoutManager *layoutManager = self.layoutManager;
    NSTextContainer *textContainer = self.textContainer;
    NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:location
                                              inTextContainer:textContainer
                               fractionOfDistanceThroughGlyph:NULL];
    if (glyphIndex >= layoutManager.numberOfGlyphs) {
        return NO;
    }

    CGRect glyphRect = [layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)
                                                inTextContainer:textContainer];
    if (!CGRectContainsPoint(glyphRect, location)) {
        return NO;
    }

    NSUInteger characterIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    if (characterIndex >= self.textStorage.length) {
        return NO;
    }

    id link = [self.textStorage attribute:NSLinkAttributeName
                                  atIndex:characterIndex
                           effectiveRange:NULL];
    return link != nil;
}

@end
