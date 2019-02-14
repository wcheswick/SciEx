//
//  WaveView.h
//  SciEx
//
//  Created by William Cheswick on 2/11/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WaveView : UIView {
    CGFloat graphWidth;     // a non-UIKit source of our width
}

@property (assign)  CGFloat graphWidth;

- (void) updateView;

@end

NS_ASSUME_NONNULL_END
