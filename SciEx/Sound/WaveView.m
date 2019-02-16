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
                         initWithFrame:CGRectMake(0, 0, LATER, f.size.height)];
        [self addSubview:waveGraphView];
    }
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    SET_VIEW_WIDTH(waveGraphView, self.frame.size.width);
    graphWidth = waveGraphView.frame.size.width;
}

- (void) showRange: (size_t) start length:(long) length {
    if (length == SHOW_FULL_RANGE)
        length = samples_count;
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.waveGraphView showSamples:start count:length];
        [self setNeedsDisplay];
    });
}

@end
