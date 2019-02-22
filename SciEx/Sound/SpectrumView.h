//
//  SpectrumView.h
//  CrackleCounter
//
//  Created by William Cheswick on 9/6/14.
//  Copyright (c) 2014 William Cheswick. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AudioClip.h"
#import "YAxisView.h"

@interface SpectrumView : UIImageView {
    AudioClip *audioClip;
}

@property (strong)   AudioClip *audioClip;

- (void) showSamplesFrom: (size_t) startSample count:(size_t) nSamples;

- (void) displayPixels:(NSData *)spectrumPixels;

@end
