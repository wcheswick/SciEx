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
@property (assign)              float leftValue;
@property (assign)              float rightValue;

@end


@implementation XAxisView

@synthesize leftLabel;
@synthesize rightLabel;
@synthesize widthLabel;
@synthesize leftValue;
@synthesize rightValue;

- (id)init {
    self = [super init];
    if (self) {
        leftLabel = [[UILabel alloc] init];
        leftLabel.textAlignment = NSTextAlignmentLeft;
        leftLabel.font = [UIFont systemFontOfSize:X_LABEL_H-LABEL_H_SLOP];
        [self addSubview:leftLabel];
        
        rightLabel = [[UILabel alloc] init];
        rightLabel.textAlignment = NSTextAlignmentRight;
        rightLabel.font = [UIFont systemFontOfSize:X_LABEL_H-LABEL_H_SLOP];
        [self addSubview:rightLabel];
        
        widthLabel = [[UILabel alloc] init];
        widthLabel.textAlignment = NSTextAlignmentCenter;
        widthLabel.font = [UIFont systemFontOfSize:X_LABEL_H-LABEL_H_SLOP];
        [self addSubview:widthLabel];
        
        self.frame = CGRectMake(0, LATER,
                                LATER, X_LABEL_H);
    }
    return self;
}

- (void) layoutSubviews {
    CGRect f = self.frame;
    f.origin.y = 2;
    f.size.height = X_LABEL_H;
    f.size.width /= 3.0;
    f.origin.x = 3;
    leftLabel.frame = f;
    [leftLabel setNeedsDisplay];
    
    f.origin.x = self.frame.size.width - f.size.width - 3;
    rightLabel.frame = f;
    [rightLabel setNeedsDisplay];
    
    f.origin.y += 5;
    f.origin.x = 0;
    f.size.width = self.frame.size.width;
    widthLabel.frame = f;
    [widthLabel setNeedsDisplay];
    [self setNeedsDisplay];
}

- (NSString *) showMs: (float) ms {
    if (ms >= 1000.0) {
        float seconds = ms/1000.0;
        int minutes = seconds / 60;
        if (minutes) {
            return [NSString stringWithFormat:@"%d:%04.1f",
                    minutes, seconds - 60*minutes];
        } else
            return [NSString stringWithFormat:@"%.1f", seconds];
    }
    if (ms > 20.0)
        return [NSString stringWithFormat:@"%.0f ms", ms];
    if (ms == 0.)
        return [NSString stringWithFormat:@"%.1f", ms];
    return [NSString stringWithFormat:@"%.1f ms", ms];
}

- (void) range: (float) left to:(float)right {
    self.leftValue = left;
    leftLabel.text = [self showMs:leftValue];
//    [leftLabel setNeedsDisplay];
    
    self.rightValue = right;
    rightLabel.text = [self showMs:rightValue];
//    [rightLabel setNeedsDisplay];
    
    float dt = right - left;
    widthLabel.text = [NSString stringWithFormat:@"width: %@", [self showMs:dt]];
//    [widthLabel setNeedsDisplay];
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
