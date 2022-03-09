//
//  SpectrumGridView.h
//  SciEx
//
//  Created by ches on 2/24/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SpectrumOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface SpectrumGridView : UIView;

- (void) gridSettings:(SpectrumOptions *)so
            startTime:(float)s
              endTime:(float) e
               startX:(int)startX;

@end

NS_ASSUME_NONNULL_END
