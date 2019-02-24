//
//  SpectrumOptions.h
//  SciEx
//
//  Created by ches on 2/23/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SpectrumOptions : NSObject {
    NSInteger pixelsPerBlock;
    NSInteger minFreq, maxFreq;
}

@property (assign)  NSInteger pixelsPerBlock;
@property (assign)  NSInteger minFreq, maxFreq;

- (void) save;

@end

NS_ASSUME_NONNULL_END
