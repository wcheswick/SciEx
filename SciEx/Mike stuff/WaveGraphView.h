//
//  WaveGraphView.h
//  SciEx
//
//  Created by William Cheswick on 2/11/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AudioClip.h"
#import "YAxisView.h"

NS_ASSUME_NONNULL_BEGIN

@interface WaveGraphView : UIView {
    AudioClip *audioClip;
}

@property (strong)   AudioClip *audioClip;

- (void) showSamplesFrom:(size_t) startSample spp:(size_t) spp;
@end

NS_ASSUME_NONNULL_END
