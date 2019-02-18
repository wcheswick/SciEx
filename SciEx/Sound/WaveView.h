//
//  WaveView.h
//  SciEx
//
//  Created by William Cheswick on 2/11/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioSample.h"

NS_ASSUME_NONNULL_BEGIN

@interface WaveView : UIView {
    AudioSample *audioSample;
    CGFloat graphWidth;     // a non-UIKit source of our width
}

@property (nonatomic, strong)   AudioSample *audioSample;
@property (assign)  CGFloat graphWidth;

- (void) useSample:(AudioSample *)newSample;
- (void) showRange: (size_t) start byteCount:(size_t) byteCount;

@end

NS_ASSUME_NONNULL_END
