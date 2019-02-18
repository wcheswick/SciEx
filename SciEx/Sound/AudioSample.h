//
//  AudioSample.h
//  SciEx
//
//  Created by ches on 2/17/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "AudioDefines.h"

#define SAMPLES_TO_MS(s)    (1000.0*(((float)s)/(float)sampleRate))

//#define MAX_SAMPLES     (2000*sampleRate)  // more than half an hour, about 80MB
//#define SAMPLE_MEM_INCR (10*sampleRatesampleRate) // more mem every ten seconds

//extern  Sample *samples;
//extern  size_t samples_alloc;
//extern  size_t samples_count;

@protocol MikeProtocol <NSObject>

- (void) audioArrivedFromMike;

@end

@interface AudioSample : NSObject <AVCaptureAudioDataOutputSampleBufferDelegate> {
    NSMutableData *samples;
    size_t rawSampleSize;
    size_t sampleRate;      // samples per second
    BOOL isMike, mikeIsOn;
    __unsafe_unretained id<MikeProtocol> caller;
}

@property (strong)  NSData *samples;
@property (assign)  size_t rawSampleSize;
@property (assign)  size_t sampleRate;
@property (assign)  BOOL isMike, mikeIsOn;
@property (assign)  __unsafe_unretained id<MikeProtocol> caller;

- (NSString *) initializeMikeForTarget:(__unsafe_unretained id<MikeProtocol>) caller;
- (NSString *) initializeFromPath: (NSString *) path;

+ (BOOL) mikeAvailable;
- (void) startMike;
- (void) stopMike;

@end
