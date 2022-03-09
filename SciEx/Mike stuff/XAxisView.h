//
//  XAxisView.h
//  CrackleCounter
//
//  Created by William Cheswick on 9/8/14.
//  Copyright (c) 2014 William Cheswick. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioClip.h"

@interface XAxisView : UIView {
    AudioClip *audioClip;
}

@property (nonatomic, strong)   AudioClip *audioClip;

- (void) range: (size_t) leftSample to:(size_t)rightSample;

@end
