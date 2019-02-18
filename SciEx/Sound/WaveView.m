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
@synthesize audioSample;

- (id)initWithFrame:(CGRect) f {
    self = [super initWithFrame:f];
    if (self) {
        audioSample = nil;
        waveGraphView = [[WaveGraphView alloc]
                         initWithFrame:CGRectMake(0, 0, LATER, f.size.height)];
        [self addSubview:waveGraphView];
    }
    return self;
}

- (void) useSample:(AudioSample *)newSample {
    audioSample = newSample;
    waveGraphView.audioSample = newSample;
    NSLog(@" audioSample:       %p", audioSample);
    NSLog(@" waveaudioSample:   %p", waveGraphView.audioSample);
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    SET_VIEW_WIDTH(waveGraphView, self.frame.size.width);
    graphWidth = waveGraphView.frame.size.width;
}

- (void) showRange: (size_t) start byteCount:(size_t) byteCount {
    NSLog(@" audioSample:       %p", audioSample);
    NSLog(@" waveaudioSample:   %p", waveGraphView.audioSample);
    assert(audioSample.samples.length);
    if (byteCount == SHOW_FULL_RANGE)
        byteCount = audioSample.samples.length;
//    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.waveGraphView showSamples:start byteCount:byteCount];
        [self setNeedsDisplay];
//    });
}

@end
