//
//  AdView.m
//  ColorFaker
//
//  Created by Ricci Adams on 2012-06-21.
//  Copyright (c) 2012 Ricci Adams. All rights reserved.
//

#import "AdView.h"

@implementation AdView {
    NSTrackingArea *_trackingArea;
    BOOL _highlighted;
}

- (void) awakeFromNib
{
    [self setFocusRingType:NSFocusRingTypeNone];

    NSTrackingAreaOptions options = (NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow );
    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
    [self addTrackingArea:_trackingArea];
}


- (BOOL) isFlipped
{
    return NO;
}

- (void) mouseEntered:(NSEvent *)theEvent
{
    [super mouseEntered:theEvent];
    [[NSCursor pointingHandCursor] push];

    _highlighted = YES;
    [self setNeedsDisplay];
}

- (void) mouseExited:(NSEvent *)theEvent
{
    [super mouseExited:theEvent];
    [NSCursor pop];

    _highlighted = NO;
    [self setNeedsDisplay];
}

- (void) drawRect:(NSRect)dirtyRect
{
    NSRect bounds = [self bounds];
    
    // Draw background gradient
    {
        NSColor *startingColor = [NSColor whiteColor];
        NSColor *endingColor;
        
        if (_highlighted) {
            endingColor = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:(0xc0 / 255.0) alpha:1.0];
        } else {
            endingColor = [NSColor colorWithDeviceWhite:(0xe0 / 255.0) alpha:1.0];
        }

        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
        [gradient drawInRect:bounds angle:-90];
    }
    
    [[NSColor colorWithDeviceWhite:0 alpha:0.33] set];
    NSRectFillUsingOperation(NSMakeRect(0, bounds.size.height - 1.0, bounds.size.width, 1.0), NSCompositeSourceOver);

    // Draw text
    {
        NSMutableAttributedString *as = [[NSMutableAttributedString alloc] init];
        
        void (^append)(NSString *, NSDictionary *) = ^(NSString *string, NSDictionary *attributes) {
            NSAttributedString *stringToAppend = [[NSAttributedString alloc] initWithString:string attributes:attributes];
            [as appendAttributedString:stringToAppend];
        };
        
        NSDictionary *normal = @{
            NSFontAttributeName: [NSFont userFontOfSize:13],
            NSForegroundColorAttributeName: [NSColor colorWithDeviceWhite:0 alpha:0.7]
        };

        NSDictionary *bold = @{
            NSFontAttributeName: [NSFont fontWithName:@"Helvetica-Bold" size:13],
            NSForegroundColorAttributeName: [NSColor colorWithDeviceWhite:0 alpha:0.8]
        };
        
        append(@"If this utility helps you, please purchase\n", normal);
        append(@"Classic Color Meter", bold);
        append(@" on the App Store.", normal);
        
        [as drawAtPoint:NSMakePoint(86, 16)];
    }

    // Draw logo
    {
        NSImage *ccm = [NSImage imageNamed:@"ccm"];
        [ccm drawAtPoint:NSMakePoint(17, 3) fromRect:NSMakeRect(0, 0, 56, 55) operation:NSCompositeSourceOver fraction:1];
    }
}


@end
