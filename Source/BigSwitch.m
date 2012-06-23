/*
    Copyright (c) 2012 Ricci Adams

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "BigSwitch.h"
#import <QuartzCore/QuartzCore.h>

@interface BigSwitch ()
@property (nonatomic, strong) CALayer *wellLayer;
@property (nonatomic, strong) CALayer *knobLayer;
@end


static CGFloat sMinKnobX = -3;
static CGFloat sMidKnobX = 20;
static CGFloat sMaxKnobX = 50;

static CGFloat sScaleRound(CGFloat f, CGFloat scale)
{
    return round(f * scale) / scale;
}


@implementation BigSwitch {
    CGPoint _mouseDownPoint;
    CGPoint _mouseDownKnobPoint;
    BOOL _canDrag;
    BOOL _didDrag;
}

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        _wellLayer = [CALayer layer];
        [_wellLayer setDelegate:self];

        _knobLayer = [CALayer layer];
        [_knobLayer setDelegate:self];

        [_knobLayer setContents:[NSImage imageNamed:@"knob"]];
        [_wellLayer setContents:[NSImage imageNamed:@"well"]];
        
        [_knobLayer setFrame:CGRectMake(-3, 1, 48, 27)];
        [_wellLayer setFrame:CGRectMake(0, 0, 95, 29)];

        CALayer *rootLayer = [CALayer layer];
        [self setLayer:rootLayer];
        [self setWantsLayer:YES];

        [rootLayer addSublayer:_wellLayer];
        [rootLayer addSublayer:_knobLayer];
    }
    
    return self;
}


- (void) dealloc
{
    [_wellLayer setDelegate:nil];
    _wellLayer = nil;

    [_knobLayer setDelegate:nil];
    _knobLayer = nil;
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    if (_didDrag) return (id) [NSNull null];
    return nil;
}


- (void) mouseDown:(NSEvent *)event
{
    if ([event clickCount] > 1)  return;

    _mouseDownPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    _mouseDownKnobPoint = [_knobLayer frame].origin;

    if (CGRectContainsPoint([_knobLayer frame], _mouseDownPoint)) {
        _canDrag = YES;
        [_knobLayer setContents:[NSImage imageNamed:@"knob_pressed"]];
    }
}


- (void) mouseUp:(NSEvent *)event
{
    if ([event clickCount] > 1)  return;
    [_knobLayer setContents:[NSImage imageNamed:@"knob"]];

    BOOL isOn;
    if (_didDrag) {
        // Move switch to on or off based on position
        isOn = [_knobLayer frame].origin.x <= sMidKnobX;
    } else {
        // toggle
        isOn = ![self isOn];
    }

    _canDrag = _didDrag = NO;
    
    if (_on == isOn) {
        _on = !isOn; // Force animation
        [self setOn:isOn animated:YES];
        
    } else {
        [self setOn:isOn animated:YES];
        [NSApp sendAction:_action to:_target from:self];
    }
}


- (void) mouseDragged:(NSEvent *)event
{
    CGPoint point = [self convertPoint:[event locationInWindow] fromView:nil];

    if (_canDrag) {
        _didDrag = YES;
        CGFloat x = (_mouseDownKnobPoint.x + (point.x - _mouseDownPoint.x));
        [self _moveSwitchToX:x];
    }
}


- (void) _moveSwitchToX:(CGFloat)x
{
    CGRect frame = [_knobLayer frame];

    x = sScaleRound(x, [[NSScreen mainScreen] userSpaceScaleFactor]);
    if (x < sMinKnobX) x = sMinKnobX;
    if (x > sMaxKnobX) x = sMaxKnobX;

    frame.origin.x = x;

    [_knobLayer setFrame:frame];
}


- (void) setOn:(BOOL)on animated:(BOOL)animated
{
    if (_on != on) {
        if (!animated) {
            [CATransaction begin];
            [CATransaction setAnimationDuration:0];
            [CATransaction setDisableActions:YES];
        }

        _on = on;
        
        CGRect frame = [_knobLayer frame];
        frame.origin.x = on ? sMaxKnobX : sMinKnobX;
        [_knobLayer setFrame:frame];
        
        if (!animated) {
            [CATransaction commit];
        }
    }
}


- (void) setOn:(BOOL)on
{
    [self setOn:on animated:NO];
}


@end
