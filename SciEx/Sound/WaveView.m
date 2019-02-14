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

@synthesize graphWidth;
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
    graphWidth = waveGraphView.frame.size.width;

    SET_VIEW_Y(xAxisView, self.frame.size.height -
               xAxisView.frame.size.height);
    SET_VIEW_WIDTH(xAxisView, waveGraphView.frame.size.width);
    
    SET_VIEW_HEIGHT(waveGraphView, xAxisView.frame.origin.y);
}

- (void) updateView {
    long count = graphWidth;
    if (count > samples_count)
        count = samples_count;
    long start = samples_count - count;
    if (start < 0) {
        count += start; //add a minus
        start = 0;
    }
    // Let the main thread do the display stuff
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.waveGraphView showSamples:start count:count];
    });
}

@end
