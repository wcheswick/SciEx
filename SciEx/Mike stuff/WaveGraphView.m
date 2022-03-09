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
@property (assign)              size_t samplesPerPixel;
@property (assign)              size_t firstSample; // in samples, not bytes

@end

@implementation WaveGraphView

@synthesize audioClip;
@synthesize samplesPerPixel, firstSample;

@synthesize leftAxis;

- (id)initWithFrame:(CGRect) f {
    self = [super initWithFrame:f];
    if (self) {
        firstSample = 0;
        samplesPerPixel = 1;
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [UIColor purpleColor].CGColor;
        self.layer.cornerRadius = 1.0;
    }
    return self;
}

- (BOOL) samplesOK {
    const Sample *bb = (const Sample *)audioClip.mikeClip.bytes;
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

- (void) showSamplesFrom:(size_t) startSample spp:(size_t) spp {
    assert(audioClip);
    assert(audioClip.samples);
    firstSample = startSample;
    assert(firstSample >= 0 && firstSample < audioClip.sampleCount);
    samplesPerPixel = spp;
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
    if (self.frame.size.width == 0) {
        CGContextRestoreGState(context);
        CGContextFlush(context);
        return;
    }
    
    if (samplesPerPixel == 0) {
        NSLog(@"inconceivable, divide by zero");
    }

    CGFloat x = layer.frame.size.width - (audioClip.sampleCount - firstSample)/samplesPerPixel;
    
    if (x < 0) {
        x = 0.0;
    }
    
    for (size_t s = firstSample; x < layer.frame.size.width; x++) {
        assert(s >= 0 && s < audioClip.sampleCount);
        Sample min = audioClip.samples[s++];
        Sample max = min;
        for (size_t i=1; i<samplesPerPixel; i++) {
            assert(s < audioClip.sampleCount);
            Sample sample = audioClip.samples[s++];
            if (sample > max)
                max = s;
            if (sample < min)
                min = s;
        }
        // draw a line between min and max, with
        // zero X axis halfway up.  maximum == minimum,
        // and maximum >= v >= -minimum
#define YF(v)    (((RAW_SAMPLE_MAX - v)/(2*RAW_SAMPLE_MAX))*self.frame.size.height)
        CGFloat y1 = YF(min);
        CGFloat y2 = YF(max);
        CGRect r = CGRectMake(x, y2, 1, y1 - y2 + 1);
        CGContextFillRect(context, r);
    }
    CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
    
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

#ifdef old

CGFloat x = 0;
size_t samplesPerScreen = layer.frame.size.width * samplesPerPixel;
size_t samplesToDisplay = audioClip.sampleCount - firstSample;
CGFloat firstX = (samplesPerScreen - samplesToDisplay)/samplesPerPixel;
if (samplesToDisplay >= samplesPerScreen)

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
#endif

