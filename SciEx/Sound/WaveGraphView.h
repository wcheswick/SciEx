//
//  WaveGraphView.h
//  SciEx
//
//  Created by William Cheswick on 2/11/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AudioSample.h"
#import "YAxisView.h"

NS_ASSUME_NONNULL_BEGIN

@interface WaveGraphView : UIView {
    AudioSample *audioSample;
}

@property (nonatomic, strong)   AudioSample *audioSample;

- (void) showSamples:(size_t) start byteCount:(size_t)byteCount;

@end

NS_ASSUME_NONNULL_END
