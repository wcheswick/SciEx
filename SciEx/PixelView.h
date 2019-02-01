//
//  PixelView.h
//  SciEx
//
//  Created by ches on 2/1/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PixelView : UIView {
    u_char *buffer;
    size_t width;
    size_t height;
}

@property (assign)  u_char *buffer;
@property (assign)  size_t width, height;

@end

NS_ASSUME_NONNULL_END
