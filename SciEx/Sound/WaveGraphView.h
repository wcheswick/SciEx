//
//  WaveGraphView.h
//  SciEx
//
//  Created by William Cheswick on 2/11/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "YAxisView.h"

NS_ASSUME_NONNULL_BEGIN

@interface WaveGraphView : UIView

- (void) showSamples:(size_t) start count:(size_t)n;

@end

NS_ASSUME_NONNULL_END
