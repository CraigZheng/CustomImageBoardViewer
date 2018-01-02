//
//  czzThreadTextView.m
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 10/05/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

#import "czzThreadTextView.h"
#import "czzMenuEnabledTableViewCell.h"

@interface czzThreadTextView()

// set the cell as property
@property (nonatomic, assign) UITableViewCell *superCell;
@property (nonatomic, assign) czzMenuEnabledTableViewCell *superMenuEnabledCell;

@end

@implementation czzThreadTextView

#pragma mark - Getters
// superCell and the touch event methods are copied from: http://stackoverflow.com/questions/2478216/how-to-pass-touch-from-a-uitextview-to-a-uitableviewcell
- (UITableViewCell *)superCell {
    if (!_superCell) {
        UIView *object = self;
        
        do {
            object = object.superview;
        } while (![object isKindOfClass:[UITableViewCell class]] && (object != nil));
        
        if (object) {
            _superCell = (UITableViewCell *)object;
        }
    }
    
    return _superCell;
}

- (czzMenuEnabledTableViewCell *)superMenuEnabledCell {
    if ([self.superCell isKindOfClass:[czzMenuEnabledTableViewCell class]]) {
        return (czzMenuEnabledTableViewCell *)self.superCell;
    }
    return nil;
}

#pragma mark - Touch overrides

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.superCell) {
        [self.superCell touchesBegan:touches withEvent:event];
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.superCell) {
        [self.superCell touchesMoved:touches withEvent:event];
    } else {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.superCell) {
        [self.superCell touchesEnded:touches withEvent:event];
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.superCell) {
        [self.superCell touchesEnded:touches withEvent:event];
    } else {
        [super touchesCancelled:touches withEvent:event];
    }
    
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL canPerformAction = [self.superCell canPerformAction:action withSender:sender];
    if (action == @selector(copy:)) {
        canPerformAction = YES;
    }
    return canPerformAction;
}


- (BOOL)resignFirstResponder {
    // Deselect text.
    self.selectedTextRange = nil;
    return YES;
}

#pragma mark - Override add gesture recognizer.

- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        
        @try {
            id targetAndAction = ((NSMutableArray *)[gestureRecognizer valueForKey:@"_targets"]).firstObject;
            NSArray <NSString *>*actions = @[@"action=loupeGesture:",           // link: no, selection: shows circle loupe and blue selectors for a second
                                             @"action=longDelayRecognizer:",    // link: no, selection: no
                                             /*@"action=smallDelayRecognizer:", // link: yes (no long press), selection: no*/
                                             @"action=oneFingerForcePan:",      // link: no, selection: shows rectangular loupe for a second, no blue selectors
                                             @"action=_handleRevealGesture:"];  // link: no, selection: no
            for (NSString *action in actions) {
                if ([[targetAndAction description] containsString:action]) {
                    [gestureRecognizer setEnabled:false];
                }
            }
            
        }
        
        @catch (NSException *e) {
        }
        
        @finally {
            [super addGestureRecognizer: gestureRecognizer];
        }
    }
}

@end
