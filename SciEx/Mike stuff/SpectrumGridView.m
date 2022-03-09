//
//  SpectrumGridView.m
//  SciEx
//
//  Created by ches on 2/24/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "SpectrumGridView.h"

@interface SpectrumGridView ()

@property (nonatomic, strong)   SpectrumOptions *spectrumOptions;
@property (assign)              float startTime, endTime;
@property (assign)              int startX;

@end

@implementation SpectrumGridView

@synthesize spectrumOptions;
@synthesize startTime, endTime;
@synthesize startX;


- (id)initWithFrame:(CGRect) f {
    self = [super initWithFrame:f];
    if (self) {
        spectrumOptions = nil;
    }
    return self;
}

- (void) gridSettings:(SpectrumOptions *)so
            startTime:(float)s endTime:(float) e
               startX:(int)sx {
    spectrumOptions = so;
    startTime = s;
    endTime = e;
    startX = sx;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    // Mere presence of this routine tells it to call drawlayer, below
}

-(void)drawLayer:(CALayer*)layer
       inContext:(CGContextRef)context {
    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context,self.frame);
    
    if (spectrumOptions) {
        CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
        CGContextStrokeRectWithWidth(context, self.frame, 5);
        //    CGContextStrokeRect(context, self.frame);
        CGContextStrokePath(context);
        
#define GY(y)    (self.frame.size.height - 1 - (y))
    
        CGContextSetRGBStrokeColor(context, 0, 0, 255, 255);
        CGContextSetLineWidth(context, 2);

        for (int x=startX; x < self.frame.size.width; x += 5*spectrumOptions.pixelsPerBlock) {
            CGContextMoveToPoint(context, x, GY(0));
            CGContextAddLineToPoint(context, x, GY(5));
            CGContextStrokePath(context);
        }
        
        for (int f=1000; f<22000; f += 1000) {
            if (f < spectrumOptions.minFreq || f > spectrumOptions.maxFreq)
                continue;
        }
    }
    CGContextRestoreGState(context);
    CGContextFlush(context);
}


@end
