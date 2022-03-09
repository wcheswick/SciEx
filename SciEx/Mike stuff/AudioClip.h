//
//  AudioClip.h
//  SciEx
//
//  Created by ches on 2/17/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "AudioDefines.h"
#import "SpectrumOptions.h"

#define SAMPLES_TO_MS(s)    (1000.0*(((float)s)/(float)sampleRate))

//#define MAX_SAMPLES     (2000*sampleRate)  // more than half an hour, about 80MB
//#define SAMPLE_MEM_INCR (10*sampleRatesampleRate) // more mem every ten seconds

//extern  Sample *samples;
//extern  size_t samples_alloc;
//extern  size_t samples_count;

@protocol MikeProtocol <NSObject>

- (void) audioArrivedFromMike;
- (void) spectrumChanged;
- (void) mikeBufferFull;

@end

@interface AudioClip : NSObject <AVCaptureAudioDataOutputSampleBufferDelegate> {
    NSMutableData *mikeClip;
    Sample *samples;
    size_t rawSampleSize;
    size_t sampleRate;      // samples per second
    size_t samplesAlloced;
    size_t sampleCount;
    size_t blockCount;
    
    BOOL isMike, mikeIsOn;
    __unsafe_unretained id<MikeProtocol> caller;
}

@property (atomic, strong)  NSMutableData *mikeClip;
@property (assign)  Sample *samples;
@property (assign)  size_t rawSampleSize;
@property (assign)  size_t sampleRate;
@property (assign)  size_t sampleCount;
@property (assign)  size_t blockCount;

@property (assign)  BOOL isMike, mikeIsOn;
@property (assign)  __unsafe_unretained id<MikeProtocol> caller;

- (NSString *) initializeMikeForTarget:(__unsafe_unretained id<MikeProtocol>) caller;
- (NSString *) initializeFromPath: (NSString *) path;

+ (BOOL) mikeAvailable;
- (void) startMike;
- (void) stopMike;

- (NSData *) spectrumPixelDataForSize:(CGSize) size
                              options:(SpectrumOptions *)spectrumOptions
                            leftBlock:(size_t)leftBlock
                               startX:(int *)startX;

- (void) close;

@end
