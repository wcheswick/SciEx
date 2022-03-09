//
//  XAxisView.m
//  CrackleCounter
//
//  Created by William Cheswick on 9/8/14.
//  Copyright (c) 2014 William Cheswick. All rights reserved.
//

#import "XAxisView.h"
#import "Defines.h"
#import "AudioDefines.h"

@interface XAxisView ()

@property (nonatomic, strong)   UILabel *leftLabel;
@property (nonatomic, strong)   UILabel *rightLabel;
@property (nonatomic, strong)   UILabel *widthLabel;
@property (assign)              size_t leftValue;
@property (assign)              size_t rightValue;

@end


@implementation XAxisView

@synthesize audioClip;
@synthesize leftLabel;
@synthesize rightLabel;
@synthesize widthLabel;
@synthesize leftValue;
@synthesize rightValue;

- (id)initWithFrame:(CGRect) f {
    self = [super initWithFrame:f];
    if (self) {
        leftLabel = [[UILabel alloc] init];
        leftLabel.textAlignment = NSTextAlignmentLeft;
        leftLabel.font = [UIFont systemFontOfSize:f.size.height*0.6];
        [self addSubview:leftLabel];
        
        rightLabel = [[UILabel alloc] init];
        rightLabel.textAlignment = NSTextAlignmentRight;
        rightLabel.font = [UIFont systemFontOfSize:f.size.height*0.6];
        [self addSubview:rightLabel];
        
        widthLabel = [[UILabel alloc] init];
        widthLabel.textAlignment = NSTextAlignmentCenter;
        widthLabel.font = [UIFont systemFontOfSize:f.size.height*0.6];
        [self addSubview:widthLabel];
    }
    return self;
}

- (void) layoutSubviews {
    CGRect f = self.frame;
    f.origin.y = 2;
    f.size.width /= 3.0;
    f.origin.x = 3;
    leftLabel.frame = f;
    [leftLabel setNeedsDisplay];
    
    f.origin.x = self.frame.size.width - f.size.width - 3;
    rightLabel.frame = f;
    [rightLabel setNeedsDisplay];
    
//    f.origin.y += 5;
    f.origin.x = 0;
    f.size.width = self.frame.size.width;
    widthLabel.frame = f;
    [widthLabel setNeedsDisplay];
    [self setNeedsDisplay];
}

- (NSString *) showTime: (float) seconds {
    if (seconds >= 1.0) {
        int minutes = seconds / 60;
        if (minutes) {
            return [NSString stringWithFormat:@"%d:%04.1f",
                    minutes, seconds - 60*minutes];
        } else
            return [NSString stringWithFormat:@"%.1f", seconds];
    }
    float ms = seconds/1000.0;
    if (ms > 20.0)
        return [NSString stringWithFormat:@"%.0f ms", ms];
    if (ms == 0.)
        return [NSString stringWithFormat:@"%.1f s", ms];
    return [NSString stringWithFormat:@"%.1f ms", ms];
}

#define SAMPLE_TO_SECONDS(s)    ((float)s/audioClip.sampleRate)

- (void) range: (size_t) leftSample to:(size_t)rightSample {
    self.leftValue = leftSample;
    leftLabel.text = [self showTime:SAMPLE_TO_SECONDS(leftValue)];
    self.rightValue = rightSample;
    rightLabel.text = [self showTime:SAMPLE_TO_SECONDS(rightValue)];
    
    size_t dt = rightValue - leftValue;
    widthLabel.text = [NSString stringWithFormat:@"%@ of %@ (%.1f%%)",
                       [self showTime:SAMPLE_TO_SECONDS(dt)],
                       [self showTime:SAMPLE_TO_SECONDS(audioClip.sampleCount)],
                       ((float)dt*100.0)/(float)(audioClip.sampleCount)];
}

- (void)drawRect:(CGRect)rect { // force draylayer call
    // Drawing code
}

-(void) drawLayer:(CALayer*)layer
       inContext:(CGContextRef)context {
    CGContextSaveGState(context);
    CGContextSetRGBFillColor(context, 1,1,1,1);
    CGContextFillRect(context,self.bounds);
    
    CGContextSetStrokeColorWithColor(context, [UIColor purpleColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, self.frame.size.width, 0);
    CGContextStrokePath(context);
    
    if (leftValue != rightValue) {
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddLineToPoint(context, 0, BIG_TICK);
        CGContextMoveToPoint(context, self.frame.size.width, 0);
        CGContextAddLineToPoint(context, self.frame.size.width, BIG_TICK);
        CGContextStrokePath(context);
    }
    
    CGContextRestoreGState(context);
    CGContextFlush(context);
}

@end
