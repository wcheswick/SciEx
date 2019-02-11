//
//  WaveView.h
//  SciEx
//
//  Created by William Cheswick on 2/11/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "XAxisView.h"
#import "YAxisView.h"

NS_ASSUME_NONNULL_BEGIN

@interface WaveView : UIView

- (void) showSamples:(size_t) from count:(size_t)n;
                     
@end

NS_ASSUME_NONNULL_END
