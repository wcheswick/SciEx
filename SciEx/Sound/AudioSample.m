//
//  AudioSample.m
//  SciEx
//
//  Created by ches on 2/17/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "AudioSample.h"

#define MIKE_BUF_SIZE_SECONDS   (60*20)

@interface AudioSample ()

@property (nonatomic, strong)   AVCaptureSession *captureSession;
@property (nonatomic, strong)   AVCaptureDevice *audioDevice;
@property (nonatomic, strong)   AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong)   AVCaptureAudioDataOutput *audioDataOutput;

@end

@implementation AudioSample

@synthesize sampleRate;
@synthesize samples;
@synthesize rawSampleSize;
@synthesize isMike, mikeIsOn;

@synthesize captureSession;
@synthesize audioDevice, audioInput;
@synthesize audioDataOutput;
@synthesize caller;


- (id)init {
    self = [super init];
    if (self) {
        caller = nil;
        isMike = mikeIsOn = NO;
        samples = nil;
    }
    return self;
}

- (NSString *) initializeMikeForTarget:(__unsafe_unretained id<MikeProtocol>) target {
    sampleRate = DEFAULT_SAMPLE_RATE;
    rawSampleSize = sizeof(RAW_SAMPLE_TYPE);
    samples = [[NSMutableData alloc] init];
    
    NSError *error;
    
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession beginConfiguration];
    
    captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    AVCaptureDevice *microphoneDevice = [AudioSample mikeDevice];
    if (!microphoneDevice)
        return @"No microphone device available.";
    
    audioInput = [AVCaptureDeviceInput
                  deviceInputWithDevice:microphoneDevice
                  error:&error];
    if (!audioInput)
        return [NSString stringWithFormat:@"microphone capture session not available: %@",
                [error localizedDescription]];
    [captureSession addInput:audioInput];
    
    audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    dispatch_queue_t audioQueue = dispatch_queue_create("ProcessAudio",
                                                        DISPATCH_QUEUE_SERIAL);
    [audioDataOutput setSampleBufferDelegate:self
                                       queue:audioQueue];
    [captureSession addOutput:audioDataOutput];
    [captureSession commitConfiguration];
    
    isMike = YES;
    caller = target;
    return nil;
}

- (NSString *) initializeFromPath: (NSString *) path {
    sampleRate = DEFAULT_SAMPLE_RATE;
    rawSampleSize = sizeof(RAW_SAMPLE_TYPE);
    samples = nil;
    isMike = NO;
    return nil;
}

+ (BOOL) mikeAvailable {
    return ([self mikeDevice] != nil);
}

+ (AVCaptureDevice *) mikeDevice {
    AVCaptureDeviceDiscoverySession *ds = [AVCaptureDeviceDiscoverySession
                                           discoverySessionWithDeviceTypes:
                                                @[AVCaptureDeviceTypeBuiltInMicrophone]
                                           mediaType:AVMediaTypeAudio
                                           position:AVCaptureDevicePositionUnspecified];
    if (ds.devices.count == 0)
        return nil;
    return (AVCaptureDevice *) [ds.devices objectAtIndex:0];
}

- (void) startMike {
    [captureSession startRunning];
    mikeIsOn = YES;
}

- (void) stopMike {
    [captureSession stopRunning];
    mikeIsOn = NO;
}

static u_long inputCount = 0;

// The microphone has delivered one or more buffers of sound.

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    size_t sampleSize = CMSampleBufferGetSampleSize(sampleBuffer,0);
    assert(sampleSize == sizeof(RAW_SAMPLE_TYPE));
    size_t sampleCount = CMSampleBufferGetNumSamples(sampleBuffer);
    size_t sampleLength = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    assert(sampleSize * sampleCount == sampleLength);

    CMBlockBufferRef blockbuff = CMSampleBufferGetDataBuffer(sampleBuffer);
    void *buffer = malloc(sampleLength);
    assert(buffer);
    OSStatus stat;
    stat = CMBlockBufferCopyDataBytes(blockbuff,
                                      0,
                                      sampleLength,
                                      buffer);
    if (stat != kCMBlockBufferNoErr) {
        NSLog(@"sound block fetch error %d", (int)stat);
        return;
    }
    NSData *rawData = [NSData dataWithBytesNoCopy:buffer length:sampleLength freeWhenDone:YES];
    
    [samples appendData:rawData];
    NSLog(@"samples length = %lu", (unsigned long)samples.length);
    inputCount += sampleCount;
    
    [caller audioArrivedFromMike];
}

#ifdef notdef

- (void) newAudioData: (NSData *)buffer {
    size_t nSamples = [buffer length]/sizeof(DEFAULT_SAMPLE_TYPE);
    if (amp.len + nSamples > amp.alloc) {
        // amp buffer is full.  If we are paused for analysis,
        // drop the data, so we don't move the buffer, else
        // forget a chunk, and continue
        if (paused) {
            overflow++;
        } else {
            size_t sToForget = amp.alloc*AMP_REDUCE_PCT/100.0;
            if (sToForget > amp.len)    // should never happen, but ok
                sToForget = amp.len;
            NSLog(@"shift, @%zu: forget %zu from %zu",
                  ampStartSampleNumber, sToForget, amp.len);
            memmove(&AMP[0], &AMP[sToForget], sizeof(AMP[0])*(amp.len - sToForget));
            amp.len -= sToForget;
            ampStartSampleNumber += sToForget;
        }
    }
    
    short *raw = (short *)[buffer bytes];
    size_t i;
    for (i=0; i<nSamples && amp.len + i < amp.alloc; i++) {
        ushort a = abs(raw[i]);
        if (a > amp.maximum)
            amp.maximum = a;
        if (a < amp.minimum)
            amp.minimum = a;
        AMP[amp.len++] = a;
    }
    
    long ampStart = amp.len - msToSamples(srcGraphWidthMs);
    long sourceLen = amp.len - ampStart;
    if (ampStart < 0)
        ampStart = 0;
    [sourceView xRangeFrom:sToMs(ampStart + ampStartSampleNumber)
                        to:sToMs(ampStart + sourceLen + ampStartSampleNumber)];
    [sourceView plotClipsFrom: ampStart width:sourceLen];
    [self setNeedsDisplay];
    busy = NO;
    
    [self processSample];
}

- (void) processSample {
    long processLen = msToSamples(procGraphWidthMs);
    long processStart = amp.len - processLen;
    if (processStart < 0) {
        processLen += processStart;
        processStart = 0;
    }
    [self processSampleFrom: processStart length:processLen];
    [processedView xRangeFrom:sToMs(processStart + ampStartSampleNumber)
                           to:sToMs(processStart + ampStartSampleNumber + processLen)];
    [processedView plotClipsFrom:0 width:processLen];
}
#endif

@end
