//
//  WaveView.m
//  SciEx
//
//  Created by William Cheswick on 2/11/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "WaveView.h"
#import "AudioDefines.h"

@interface WaveView ()

@property (strong, nonatomic)   YAxisView *leftAxis;
@property (strong, nonatomic)   XAxisView *bottomAxis;
@property (assign)              size_t firstSample;
@property (assign)              size_t sampleCount;

@end

@implementation WaveView

@synthesize leftAxis, bottomAxis;
@synthesize firstSample, sampleCount;

- (id)initWithFrame:(CGRect) f {
    self = [super initWithFrame:f];
    if (self) {
        firstSample = 0;
        sampleCount = 0;
    }
    return self;
}

- (void) showSamples:(size_t) from count:(size_t)n {
    firstSample = from;
    sampleCount = n;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    // Mere presence of this routine tells it to call drawlayer, below
}

#define BIG_TICK    10
#define SMALL_TICK  4

#define BELOW_T     30
#define LEFT_Y  50
#define RIGHT_Y 50

- (void) pause {
    
}

-(void)drawLayer:(CALayer*)layer
       inContext:(CGContextRef)context {
    
//    CGFloat xAxis = rect.origin.y + rect.size.height/2.0;

    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context,self.bounds);
    if (sampleCount == 0 || self.frame.size.width == 0) {
        CGContextRestoreGState(context);
        CGContextFlush(context);
        return;
    }
    
    float samplesPerPixel = sampleCount/self.frame.size.width;
    
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
    float maximum, minimum;
    
    maximum = INT16_MAX;
    minimum = INT16_MIN;
    
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
        size_t last = sampleCount;
    Sample min, max;
    
    for (size_t i = firstSample; i<last; i += compression) {
        min = max = samples[i];
        for (size_t j=1; j<compression && i+j<last; j++) {
            Sample v = samples[i+j];
            if (v > max)
                max = v;
            if (v < min)
                min = v;
        }
        // draw a line between min and max, with
        // zero X axis halfway up.  maximum == minimum,
        // and maximum >= v >= -minimum
#define YF(v)    (((maximum - v)/(2*maximum))*self.frame.size.height)
        CGFloat y1 = YF(min);
        CGFloat y2 = YF(max);
        CGRect r = CGRectMake(x, y2, pixelsPerPoint, y1- y2 + 1);
        CGContextFillRect(context, r);
        x += pixelsPerPoint;
    }
    
    CGContextRestoreGState(context);
    CGContextFlush(context);
}

@end
