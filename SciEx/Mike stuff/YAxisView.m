//
//  YAxisView.m
//  CrackleCounter
//
//  Created by William Cheswick on 9/8/14.
//  Copyright (c) 2014 William Cheswick. All rights reserved.
//

#import "YAxisView.h"
#import "AudioDefines.h"

@interface YAxisView ()

@property (assign)  float yMin;
@property (assign)  float yMax;
@property (nonatomic, strong)   UILabel *topLabel;
@property (nonatomic, strong)   UILabel *botLabel;

@end

@implementation YAxisView

@synthesize yMax;
@synthesize yMin;
@synthesize topLabel;
@synthesize botLabel;

- (id)init {
    self = [super init];
    if (self) {
        yMax = yMin = 0;

        topLabel = [[UILabel alloc] init];
        topLabel.textAlignment = NSTextAlignmentRight;
        topLabel.font = [UIFont systemFontOfSize:Y_LABEL_H - LABEL_H_SLOP];
        [self addSubview:topLabel];
        
        botLabel = [[UILabel alloc] init];
        botLabel.textAlignment = NSTextAlignmentRight;
        botLabel.font = [UIFont systemFontOfSize:Y_LABEL_H - LABEL_H_SLOP];
        [self addSubview:botLabel];

    }
    return self;
}

- (void) range: (float) min upto:(float)max {
    yMin = min;
    NSString *fmt = @"%6.0f";
    if (max <= 10.0)
        fmt = @"%4.1f";
    
    botLabel.text = [NSString stringWithFormat:fmt, min];
    [botLabel setNeedsDisplay];
    
    yMax = max;
    topLabel.text = [NSString stringWithFormat:fmt, max];
    [topLabel setNeedsDisplay];
}

#define LABEL_FUDGE 3
#define LABEL_H_SEP   5

- (void) layoutSubviews {
    CGRect f = CGRectMake(0, LABEL_FUDGE, self.frame.size.width - LABEL_H_SEP, Y_LABEL_H);
    topLabel.frame = f;
    [topLabel setNeedsDisplay];
    
    f.origin.y += self.frame.size.height - LABEL_FUDGE - Y_LABEL_H - 2;
    botLabel.frame = f;
    [botLabel setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect { // force draylayer call
    // Drawing code
}

-(void)drawLayer:(CALayer*)layer
       inContext:(CGContextRef)context {
    CGContextSaveGState(context);
    CGContextSetRGBFillColor(context, 1,1,1,1);
    CGContextFillRect(context,self.bounds);

    CGFloat XAxis = self.frame.size.width;
    CGFloat YBottom = self.frame.size.height;
    
    CGContextSetStrokeColorWithColor(context, [UIColor purpleColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    CGContextMoveToPoint(context, XAxis, 0);
    CGContextAddLineToPoint(context, XAxis, YBottom);
    CGContextStrokePath(context);

    if (yMin != yMax) {
        CGContextMoveToPoint(context, XAxis, 0);
        CGContextAddLineToPoint(context, XAxis-BIG_TICK, 0);
        CGContextMoveToPoint(context, XAxis, YBottom);
        CGContextAddLineToPoint(context, XAxis-BIG_TICK, YBottom);
        CGContextStrokePath(context);
    }
    
    CGContextRestoreGState(context);
    CGContextFlush(context);
}

@end
