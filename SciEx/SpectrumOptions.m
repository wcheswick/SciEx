//
//  SpectrumOptions.m
//  SciEx
//
//  Created by ches on 2/23/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "SpectrumOptions.h"

#define kPixelsPerBlock @"PixelsPerBlock"
#define kMinFreq        @"MinFreq"
#define kMaxFreq        @"MaxFreq"

@implementation SpectrumOptions

@synthesize pixelsPerBlock, minFreq, maxFreq;

- (id)init {
    self = [super init];
    if (self) {
        pixelsPerBlock = [[NSUserDefaults standardUserDefaults]integerForKey:kPixelsPerBlock];
        minFreq = [[NSUserDefaults standardUserDefaults] integerForKey:kMinFreq];
        maxFreq = [[NSUserDefaults standardUserDefaults]
                   integerForKey:kMaxFreq];
        if (!pixelsPerBlock || !minFreq || !maxFreq) {
            pixelsPerBlock = 3;
            minFreq = 20;
            maxFreq = 4000;
            [self save];
        }
    }
    return self;
}

- (void) save {
    [[NSUserDefaults standardUserDefaults] setInteger:pixelsPerBlock forKey:kPixelsPerBlock];
    [[NSUserDefaults standardUserDefaults] setInteger:minFreq forKey:kMinFreq];
    [[NSUserDefaults standardUserDefaults] setInteger:maxFreq forKey:kMaxFreq];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
