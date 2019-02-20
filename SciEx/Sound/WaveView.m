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
@synthesize audioClip;

- (id)initWithFrame:(CGRect) f {
    self = [super initWithFrame:f];
    if (self) {
        audioClip = nil;
        waveGraphView = [[WaveGraphView alloc]
                         initWithFrame:CGRectMake(0, 0, LATER, f.size.height)];
        [self addSubview:waveGraphView];
    }
    return self;
}

- (void) useClip:(AudioClip *)newClip {
    audioClip = newClip;
    waveGraphView.audioClip = newClip;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    SET_VIEW_WIDTH(waveGraphView, self.frame.size.width);
    graphWidth = waveGraphView.frame.size.width;
}

#define MS_TO_BYTES(ms) (((ms)/1000.0) * (float)audioClip.rawSampleSize * (float)audioClip.sampleRate)

- (void) showRangeFrom: (size_t) startSample count:(size_t) nSamples {
    if (startSample + nSamples > audioClip.sampleCount)
        nSamples = audioClip.sampleCount - startSample;
    [self.waveGraphView showSamplesFrom:startSample count:nSamples];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self setNeedsDisplay];
    });
}

@end
