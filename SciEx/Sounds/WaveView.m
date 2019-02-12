//
//  WaveView.m
//  SciEx
//
//  Created by William Cheswick on 2/11/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "WaveView.h"
#import "WaveGraphView.h"
#import "Defines.h"
#import "AudioDefines.h"

#import "XAxisView.h"

@interface WaveView ()

@property (nonatomic, strong)   WaveGraphView *waveGraphView;
@property (nonatomic, strong)   XAxisView *xAxisView;

@end

@implementation WaveView

@synthesize waveGraphView;
@synthesize xAxisView;

- (id)initWithFrame:(CGRect) f {
    self = [super initWithFrame:f];
    if (self) {
        waveGraphView = [[WaveGraphView alloc]
                         initWithFrame:CGRectMake(0, 0, LATER, LATER)];
        [self addSubview:waveGraphView];
        
        xAxisView = [[XAxisView alloc] init];
        [self addSubview:xAxisView];
    }
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    SET_VIEW_WIDTH(waveGraphView, self.frame.size.width);

    SET_VIEW_Y(xAxisView, self.frame.size.height -
               xAxisView.frame.size.height);
    SET_VIEW_WIDTH(xAxisView, waveGraphView.frame.size.width);
    
    SET_VIEW_HEIGHT(waveGraphView, xAxisView.frame.origin.y);
}

- (void) updateView {
//    [waveGraphView showSamples:0 count:samples_count];
#ifdef  notnow
    CGFloat start = samples_count - waveGraphView.frame.size.width;
    if (start < 0)
        start = 0;
    [waveGraphView showSamples:start
                         count:waveGraphView.frame.size.width];
    [xAxisView range:SAMPLES_TO_MS(start)
                  to:SAMPLES_TO_MS(start + waveGraphView.frame.size.width)];
#endif
}

@end
