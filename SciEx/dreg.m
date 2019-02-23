#ifdef dreg
//
//  AudioExhibitVC.m
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "AudioExhibitVC.h"

@interface AudioExhibitVC ()

@end

@implementation AudioExhibitVC


- (id)init {
    self = [super init];
    if (self) {
        mikeIsOn = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

@end

#ifdef dreg
session = [AVAudioSession sharedInstance];

NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithFloat: 44100.0],                 AVSampleRateKey,
                          [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                          [NSNumber numberWithInt: 1],                         AVNumberOfChannelsKey,
                          [NSNumber numberWithInt: AVAudioQualityMax],         AVEncoderAudioQualityKey,
                          nil];
if (session == nil) {
    return @"no session available";
}

if (![session setActive:YES error:&error]) {
    return [NSString stringWithFormat:@"setActive: %@",
            [error localizedDescription]];
}

if (![session setCategory:AVAudioSessionCategoryRecord error:&error]) {
    return [NSString stringWithFormat:@"setCategory: %@",
            [error localizedDescription]];
}

if (![session setMode:AVAudioSessionModeMeasurement error:&error]) {
    return [NSString stringWithFormat:@"setMode: %@",
            [error localizedDescription]];
}

if (![session setMode:AVAudioSessionModeMeasurement error:&error]){
    return [NSString stringWithFormat:@"setMode: %@",
            [error localizedDescription]];
}

if (![session setPreferredSampleRate:DEFAULT_SAMPLE_RATE error:&error]){
    return [NSString stringWithFormat:@"setPreferredSampleRate: %@",
            [error localizedDescription]];
}

if (![session setPreferredIOBufferDuration: 0.050 error:&error]) {
    return [NSString stringWithFormat:@"setPreferredIOBufferDuration: %@",
            [error localizedDescription]];
}

#ifdef notdef
if (![session setCategory:AVAudioSessionCategorySoloAmbient
              withOptions: AVAudioSessionCategoryOptionAllowBluetooth
                    error:&error]){
    return [NSString stringWithFormat:@"setCategory AVAudioSessionCategorySoloAmbient: %@",
            [error localizedDescription]];
}
#endif

if (![session setInputGain:1.0 error:&error]){
    return [NSString stringWithFormat:@"setInputGain: %@",
            [error localizedDescription]];
}
#endif

#endif



#ifdef notdef

- (void) newAudioData: (NSData *)buffer {
    size_t nSamples = [buffer length]/sizeof(DEFAULT_SAMPLE_TYPE);
    if (amp.len + nSamples > amp.alloc) {
        // amp buffer is full.  If we are paused for analysis,
        // drop the data, so we don't move the buffer, else
        // forget a chunk, and continue
        if (paused) {
            overflow++;
        } else {
            size_t sToForget = amp.alloc*AMP_REDUCE_PCT/100.0;
            if (sToForget > amp.len)    // should never happen, but ok
                sToForget = amp.len;
            NSLog(@"shift, @%zu: forget %zu from %zu",
                  ampStartSampleNumber, sToForget, amp.len);
            memmove(&AMP[0], &AMP[sToForget], sizeof(AMP[0])*(amp.len - sToForget));
            amp.len -= sToForget;
            ampStartSampleNumber += sToForget;
        }
    }
    
    short *raw = (short *)[buffer bytes];
    size_t i;
    for (i=0; i<nSamples && amp.len + i < amp.alloc; i++) {
        ushort a = abs(raw[i]);
        if (a > amp.maximum)
            amp.maximum = a;
        if (a < amp.minimum)
            amp.minimum = a;
        AMP[amp.len++] = a;
    }
    
    long ampStart = amp.len - msToSamples(srcGraphWidthMs);
    long sourceLen = amp.len - ampStart;
    if (ampStart < 0)
        ampStart = 0;
        [sourceView xRangeFrom:sToMs(ampStart + ampStartSampleNumber)
                            to:sToMs(ampStart + sourceLen + ampStartSampleNumber)];
    [sourceView plotClipsFrom: ampStart width:sourceLen];
    [self setNeedsDisplay];
    busy = NO;
    
    [self processSample];
}

- (void) processSample {
    long processLen = msToSamples(procGraphWidthMs);
    long processStart = amp.len - processLen;
    if (processStart < 0) {
        processLen += processStart;
        processStart = 0;
    }
    [self processSampleFrom: processStart length:processLen];
    [processedView xRangeFrom:sToMs(processStart + ampStartSampleNumber)
                           to:sToMs(processStart + ampStartSampleNumber + processLen)];
    [processedView plotClipsFrom:0 width:processLen];
}
#endif


#ifdef OLD
/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

-(void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context {
    CGContextSaveGState(context);
    
    CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
    CGContextFillRect(context,self.bounds);
    
    if (audioClip.samples == NULL)
        return;
    
    CGFloat tAxis = self.bounds.origin.y + 150;
    CGFloat yAxis = self.bounds.origin.x + LEFT_Y;
    CGFloat tLen = self.bounds.size.width - yAxis - RIGHT_Y - 1;
#ifdef SAMPLE_DEBUG
    tLen = 300; // 3/4 of our total, requiring squeezing
    CGFloat yLen = tAxis - 1;
#endif
    
    CGContextSetRGBFillColor(context, 0,0,0,1.0);
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    // t axis
    CGContextFillRect(context,CGRectMake(yAxis,tAxis,tLen, 1));
    CGContextFillRect(context,CGRectMake(yAxis,tAxis,1, BIG_TICK));
    CGContextFillRect(context,CGRectMake(yAxis+tLen-1,tAxis,1, BIG_TICK));
    
    // y axis
    CGContextFillRect(context,CGRectMake(yAxis, tAxis-tLen+1, 1, tLen));
    CGContextFillRect(context,CGRectMake(yAxis-BIG_TICK, tAxis, BIG_TICK, 1));
    CGContextFillRect(context,CGRectMake(yAxis-BIG_TICK, tAxis-tLen+1, BIG_TICK, 1));
    
#define HIST_H  50
    
#ifdef QM
    // y hist on the right
    float dy = (float)yLen/topHist;
    float y = tAxis - dy;
    CGContextSetRGBFillColor(context, 0,1,0,1);
    for (size_t i=0; i<topHist; i++) {
        CGContextFillRect(context,
                          CGRectMake(yAxis + tLen+2, y,
                                     (log(yHist[i])/log(maxHist))*HIST_H + 1, dy));
        y -= dy;
    }
#endif
    // y ticks
    
#ifdef powerdisplay
    switch (displayType) {
        case PowerDisplay: {
            if (rangeStart >= rangeEnd)
                NSLog(@"oops 1");
            size_t sCount = rangeEnd - rangeStart;
            if (sCount == 0)
                break;
            samplesPerPoint = (sCount + (tLen - 1))/tLen;
            if (samplesPerPoint == 0)
                samplesPerPoint = 1;
            pixelsPerPoint = (float)tLen/(sCount/samplesPerPoint);
            size_t nPoints = tLen/pixelsPerPoint;
            CGFloat powers[nPoints];
            CGFloat correlated[nPoints];
            size_t s = rangeStart;
            double powerMax = -1.0;
            for (size_t t = 0; t<nPoints; t++) {
                powers[t] = -1;
                correlated[t] = 0;
                for (size_t i=0; i<samplesPerPoint; i++) {
                    if (s >= numberOfSamples)
                        NSLog(@"Ooops 2");
                    CGFloat ts = abs(samples[s++]);
                    if (ts > powers[t])
                        powers[t] = ts;
                    if (correlation && correlation[i] > correlated[t])
                        correlated[t] = correlation[i];
                }
                if (powers[t] > powerMax)
                    powerMax = powers[t];
            }
            
            // show selected range, if it exists
            
            if (selectedRight != selectedLeft) {
                CGFloat x1 = [self sToX: selectedLeft];
                CGFloat x2 = [self sToX: selectedRight];
                CGContextSetRGBFillColor(context, 1,1,0.25,1);
                CGContextFillRect(context,CGRectMake(x1, tAxis-1-yLen, x2 - x1 + 1, yLen));
            }
            
            // debug cursor, if tapped
            
            if (tapX != NO_TAP) {
                CGColorRef c = [UIColor grayColor].CGColor;
                CGContextSetFillColorWithColor(context, c);
                CGContextFillRect(context, CGRectMake(tapX, 0, 1, yLen));
                c = [UIColor purpleColor].CGColor;
                size_t s = [self xToSample:tapX];
                NSLog(@"tap at %zu", s);
                CGFloat x = [self sToX:s];
                CGContextFillRect(context, CGRectMake(x, tAxis-1-yLen, 2, yLen));
            }
            
            // show audio plot
            
            CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
            for (size_t t = 0; t<nPoints; t++) {
                float sYlen = (powers[t]/yMax) * yLen;
                if (sYlen > yLen)
                    sYlen = yLen;
                double y = tAxis - sYlen;
                double x = yAxis + (t+1)*pixelsPerPoint;
                if (t == 0)
                    CGContextMoveToPoint(context, x, y);
                else
                    CGContextAddLineToPoint(context, x, y);
            }
            CGContextStrokePath(context);
            
            // fft
            
            if (fft) {
                float max = 0;
                for (size_t i=0; i<FFT_LEN/2; i++)
                    if (log(fft[i]) > max)
                        max = log(fft[i]);
                float yMin = tAxis + 50;
                float yMx = yMin + 100;
                float fMin = yAxis;
                float fMax = yAxis + tLen;
                CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
                CGContextMoveToPoint(context, fMin, yMx);
                for (size_t fi = 0; fi < FFT_LEN/2; fi++) {
                    float x = ((float)fi/(float)(FFT_LEN/2)) * (fMax - fMin) + fMin;
                    float y = yMx - (log(fft[fi])/max) * (yMx - yMin);
                    CGContextAddLineToPoint(context, x, y);
                }
                CGContextAddLineToPoint(context, fMax, yMx);
            }
            
            // analysis
            
            if (correlation) {
                CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
                for (size_t t = 0; t<nPoints; t++) {
                    float sYlen = correlated[t] * yLen;
                    double y = tAxis - sYlen;
                    double x = yAxis + (t+1)*pixelsPerPoint;
                    NSLog(@"c %.1f  %4.0f", x, y);
                    if (t == 0)
                        CGContextMoveToPoint(context, x, y);
                    else
                        CGContextAddLineToPoint(context, x, y);
                }
                CGContextStrokePath(context);
            }
            
            // t ticks
            
            CGFloat leftAxisMs = [self sToMs:rangeStart];
            CGFloat rightAxisMs = [self sToMs:rangeEnd];
            CGFloat msPerPixel = ((CGFloat)(rightAxisMs - leftAxisMs)/tLen)/pixelsPerPoint;
            [caller displayWidth:rightAxisMs - leftAxisMs];
            int minMsPerTick = MIN_PIX_PER_TICK*msPerPixel;
            int msPerTick = pow(10, floor(log(minMsPerTick)/log(10.0) + 1));
            if (msPerTick == 0)
                msPerTick = 1;
            CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
            BOOL isBlue = YES;
            int ms = msPerTick*floor(leftAxisMs/msPerTick);
            if (ms < leftAxisMs)
                ms += msPerTick;
            //            NSLog(@"t ticks %d", msPerTick);
            while (ms < rightAxisMs) {
                CGFloat x = yAxis + (ms - leftAxisMs)/msPerPixel*pixelsPerPoint;
                int len;
                BOOL blue = YES;
                if (ms % 60000 == 0)
                    len = 25;
                else if (ms % 10000 == 0)
                    len = 21;
                else if (ms % 5000 == 0)
                    len = 16;
                else if (ms % 1000 == 0)
                    len = 15;
                else if (ms % 100 == 0)
                    len = 12;
                else if (ms % 10 == 0)
                    len = 9;
                else if (ms % 5 == 0)
                    len = 6;
                else {
                    len = 3;
                    blue = NO;
                }
                if (blue && !isBlue) {
                    CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
                    isBlue = YES;
                } else if (!blue && isBlue) {
                    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
                    isBlue = NO;
                }
                CGContextMoveToPoint(context, x, tAxis);
                CGContextAddLineToPoint(context, x, tAxis+len);
                ms += msPerTick;
            }
            CGContextStrokePath(context);
            break;
        }
        case FreqDisplay:
            break;
    }
#endif
    
#ifdef notyet
    CTFontRef sysUIFont = CTFontCreateUIFontForLanguage(kCTFontSystemFontType,
                                                        10.0, NULL);
    CGColorRef color = [UIColor blueColor].CGColor;
    NSDictionary *attributesDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (__bridge id)sysUIFont, (id)kCTFontAttributeName,
                                    color, (id)kCTForegroundColorAttributeName, nil];
    
    // flip the coordinate system. Text has the origin in the lower left
    // of the audio display.
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    NSAttributedString *s;
    CTLineRef line;
    
    // draw start time
    s = [[NSAttributedString alloc]
         initWithString:[self timeString:audioClip.rangeStart]
         attributes:attributesDict];
    line = CTLineCreateWithAttributedString((CFAttributedStringRef)s);
    CGContextSetTextPosition(context, yAxis, 10);
    CTLineDraw(line, context);
    CFRelease(line);
    
    // draw finish time
    s = [[NSAttributedString alloc]
         initWithString:[self timeString:audioClip.rangeEnd]
         attributes:attributesDict];
    line = CTLineCreateWithAttributedString((CFAttributedStringRef)s);
    CGContextSetTextPosition(context, yAxis + tLen - 50, 10);
    CTLineDraw(line, context);
    CFRelease(line);
    CFRelease(sysUIFont);
#endif
    
    CGContextRestoreGState(context);
    CGContextFlush(context);
}

#ifdef notdef

// fft

if (fft) {
    float max = 0;
    for (size_t i=0; i<FFT_LEN/2; i++)
        if (log(fft[i]) > max)
            max = log(fft[i]);
            float yMin = tAxis + 50;
            float yMx = yMin + 100;
            float fMin = yAxis;
            float fMax = yAxis + tLen;
            CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
            CGContextMoveToPoint(context, fMin, yMx);
            for (size_t fi = 0; fi < FFT_LEN/2; fi++) {
                float x = ((float)fi/(float)(FFT_LEN/2)) * (fMax - fMin) + fMin;
                float y = yMx - (log(fft[fi])/max) * (yMx - yMin);
                CGContextAddLineToPoint(context, x, y);
            }
    CGContextAddLineToPoint(context, fMax, yMx);
}

// analysis

if (correlation) {
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    for (size_t t = 0; t<nPoints; t++) {
        float sYlen = correlated[t] * yLen;
        double y = tAxis - sYlen;
        double x = yAxis + (t+1)*pixelsPerPoint;
        NSLog(@"c %.1f  %4.0f", x, y);
        if (t == 0)
            CGContextMoveToPoint(context, x, y);
        else
            CGContextAddLineToPoint(context, x, y);
    }
    CGContextStrokePath(context);
}
#endif
#endif
