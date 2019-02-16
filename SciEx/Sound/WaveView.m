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

@interface WaveView ()

@property (nonatomic, strong)   WaveGraphView *waveGraphView;

@end

@implementation WaveView

@synthesize graphWidth;
@synthesize waveGraphView;

- (id)initWithFrame:(CGRect) f {
    self = [super initWithFrame:f];
    if (self) {
        waveGraphView = [[WaveGraphView alloc]
                         initWithFrame:CGRectMake(0, 0, LATER, LATER)];
        [self addSubview:waveGraphView];
    }
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    SET_VIEW_WIDTH(waveGraphView, self.frame.size.width);
    graphWidth = waveGraphView.frame.size.width;
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
