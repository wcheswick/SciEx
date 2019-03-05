//
//  WaveGraphView.m
//  SciEx
//
//  Created by William Cheswick on 2/11/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "WaveGraphView.h"
#import "AudioDefines.h"


@interface WaveGraphView ()

@property (strong, nonatomic)   YAxisView *leftAxis;
@property (assign)              size_t firstDisplay; // in samples, not bytes
@property (assign)              size_t numberDisplayed; // in samples, not bytes

@end

@implementation WaveGraphView

@synthesize audioClip;
@synthesize leftAxis;
@synthesize firstDisplay, numberDisplayed;

- (id)initWithFrame:(CGRect) f {
    self = [super initWithFrame:f];
    if (self) {
        firstDisplay = 0;
        numberDisplayed = 0;
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [UIColor purpleColor].CGColor;
        self.layer.cornerRadius = 1.0;
    }
    return self;
}

- (BOOL) samplesOK {
    const Sample *bb = (const Sample *)audioClip.mikeClip.mutableBytes;
    assert(audioClip.sampleCount == audioClip.mikeClip.length/sizeof(Sample));
    for (size_t i=0; i<audioClip.sampleCount; i++) {
        Sample a = audioClip.samples[i];
        Sample b = bb[i];
        if (a != b) {
            NSLog(@"oops, @ %zu: %04x != %04x", i, a, b);
            return NO;
        }
    }
    return YES;
}

- (void) showSamplesFrom:(size_t) startSample count:(size_t) nSamples {
    assert(audioClip);
    assert(audioClip.samples);
    firstDisplay = startSample;
    numberDisplayed = nSamples;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self setNeedsDisplay];
    });
}

- (void)drawRect:(CGRect)rect {
    // Mere presence of this routine tells it to call drawlayer, below
}

#define BIG_TICK    10
#define SMALL_TICK  4

#define BELOW_T     30
#define LEFT_Y  50
#define RIGHT_Y 50

-(void)drawLayer:(CALayer*)layer
       inContext:(CGContextRef)context {
    
//    CGFloat xAxis = rect.origin.y + rect.size.height/2.0;

    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context,self.bounds);
    if (numberDisplayed == 0 || self.frame.size.width == 0) {
        CGContextRestoreGState(context);
        CGContextFlush(context);
        return;
    }
    
    float samplesPerPixel = numberDisplayed/self.frame.size.width;
    
    if (samplesPerPixel == 0) {
        NSLog(@"inconceivable, divide by zero");
    }
    float compression, pixelsPerPoint;
    
    if (samplesPerPixel <= 1.0) {
        compression = 1;
        pixelsPerPoint = 1.0/samplesPerPixel;
    } else {
        compression = floor(samplesPerPixel) + 1;
        pixelsPerPoint = self.frame.size.width/(self.frame.size.width/compression);
    }
    if (compression == 0) {
        NSLog(@"Inconceivable, divide by zero");
    }
    
    size_t standardCount = 0;
    
    float maximum = RAW_SAMPLE_MAX;
//    float minimum = RAW_SAMPLE_MIN;

    UIColor *color;
    switch (standardCount++) {    // GNUPlot, anyone?  It will do for now
        case 0:
            color = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.5];
            break;
        case 1:
            color = [UIColor colorWithRed:.5 green:.5 blue:0 alpha:1];
            break;
        case 2:
            color = [UIColor colorWithRed:1 green:0 blue:0 alpha:.4];
            break;
        default:
            color = [UIColor colorWithRed:.8 green:.8 blue:.8 alpha:.5];
    }
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    CGFloat x = 0;
    
    Sample min, max;

    for (size_t i = 0; i<numberDisplayed; i += compression) {
        size_t p = i+firstDisplay;
        min = max = audioClip.samples[p];
        for (size_t j=1; j<compression && p+j < audioClip.sampleCount; j++) {
            if (p+j >= audioClip.sampleCount) {
                NSLog(@"***  %zu + %zu >= %zu", p, j, audioClip.sampleCount);
                assert(p+j < audioClip.sampleCount); // XXXXXXXX 1023+1
            }
            Sample s = audioClip.samples[p+j];
            if (s > max)
                max = s;
            if (s < min)
                min = s;
        }
        // draw a line between min and max, with
        // zero X axis halfway up.  maximum == minimum,
        // and maximum >= v >= -minimum
#define YF(v)    (((maximum - v)/(2*maximum))*self.frame.size.height)
        CGFloat y1 = YF(min);
        CGFloat y2 = YF(max);
        CGRect r = CGRectMake(x++, y2, 1, y1 - y2 + 1);
        CGContextFillRect(context, r);
    }
    
    CGFloat xAxis = self.frame.origin.y + self.frame.size.height/2.0;
    
    CGContextSetStrokeColorWithColor(context, [UIColor purpleColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    CGContextMoveToPoint(context, 0, xAxis);
    CGContextAddLineToPoint(context, self.frame.size.width-1, xAxis);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
    CGContextFlush(context);
}

@end
