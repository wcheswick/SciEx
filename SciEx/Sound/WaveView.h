//
//  WaveView.h
//  SciEx
//
//  Created by William Cheswick on 2/11/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioClip.h"

NS_ASSUME_NONNULL_BEGIN

@interface WaveView : UIView {
    AudioClip *audioClip;
    CGFloat graphWidth;     // a non-UIKit source of our width
}

@property (strong)   AudioClip *audioClip;
@property (assign)  CGFloat graphWidth;

- (void) useClip:(AudioClip *)newClip;
- (void) showRangeFrom: (size_t) startSample spp:(size_t) spp;

@end

NS_ASSUME_NONNULL_END
