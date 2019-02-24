//
//  AudioClip.m
//  SciEx
//
//  Created by ches on 2/17/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#include <Accelerate/Accelerate.h>

#import "AudioClip.h"

// These fixed buffer lengths are both crude hacks because I've been spending
// too much time on dynamic allocation and appropriate locks for them during
// reallocations.

#define MIKE_BUF_SIZE_SECONDS   (60*20)
#define MAX_SPECTRAL_BLOCKS     (2000)
#define MAX_DB_BLOCKS           (2000)

typedef struct FFTBlock {
    float raw[FFT_LEN/2 + 1];
    float min, max;
} FFTBlock;

typedef struct DBBlock {
    float DB[FFT_LEN/2 + 1];
    float min, max;
} DBBlock;

size_t DBsAlloced = 0;

static FFTBlock *blocks[MAX_SPECTRAL_BLOCKS];
static DBBlock *DBblocks[MAX_DB_BLOCKS];

static float hannFilter[FFT_LEN];

@interface AudioClip ()

@property (assign)              size_t samplesAlloced;
@property (nonatomic, strong)   AVCaptureSession *captureSession;
@property (nonatomic, strong)   AVCaptureDevice *audioDevice;
@property (nonatomic, strong)   AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong)   AVCaptureAudioDataOutput *audioDataOutput;

@property (assign)              size_t blocksAlloc;

@end

@implementation AudioClip

@synthesize sampleRate;
@synthesize samples;
@synthesize rawSampleSize;
@synthesize isMike, mikeIsOn;

@synthesize samplesAlloced, sampleCount;

@synthesize blockCount, blocksAlloc;

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
        samplesAlloced = 0;
        sampleCount = 0;
        blockCount = 0;
        blocksAlloc = 0;
    }
    return self;
}

- (NSString *) initializeMikeForTarget:(__unsafe_unretained id<MikeProtocol>) target {
    sampleRate = DEFAULT_SAMPLE_RATE;
    rawSampleSize = sizeof(RAW_SAMPLE_TYPE);
    samplesAlloced = MAX_MIKE_LEN;  // the full monte, for now
    samples = (Sample *)calloc(MAX_MIKE_LEN, sizeof(Sample));
    if (!samples) {
        samplesAlloced = 0;
        return @"Not enough memory for the microphone";
    }
    sampleCount = 0;
    [self setupFFT];

    NSError *error;
    
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession beginConfiguration];
    
    captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    AVCaptureDevice *microphoneDevice = [AudioClip mikeDevice];
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

- (void) setupFFT {
    blocksAlloc = MAX_SPECTRAL_BLOCKS;
    blockCount = 0;
    vDSP_hann_window (hannFilter, FFT_LEN, 0);

    for (int i=0; i<MAX_SPECTRAL_BLOCKS; i++) {
        FFTBlock *b = malloc(sizeof(FFTBlock));
        assert(b);
        blocks[i] = b;
    }
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

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    if (!captureSession.running) {
        NSLog(@"data without capture running.  Hmm. Ignored");
        return;
    }
    size_t sampleSize = CMSampleBufferGetSampleSize(sampleBuffer,0);
    assert(sampleSize == sizeof(RAW_SAMPLE_TYPE));
    size_t newCount = CMSampleBufferGetNumSamples(sampleBuffer);
    size_t incomingLength = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    assert(sampleSize * newCount == incomingLength);

    if (sampleCount*sizeof(Sample) + incomingLength > samplesAlloced) {
        NSLog(@" mike buffer full, %zu + %zu > %zu",
              sampleCount, incomingLength, samplesAlloced);
        [self stopMike];
        [caller mikeBufferFull];
        return;
    }
    CMBlockBufferRef blockbuff = CMSampleBufferGetDataBuffer(sampleBuffer);
    OSStatus stat;
    stat = CMBlockBufferCopyDataBytes(blockbuff,
                                      0,
                                      incomingLength,
                                      &samples[sampleCount]);
    if (stat != kCMBlockBufferNoErr) {
        NSLog(@"sound block fetch error %d", (int)stat);
        return;
    }
    sampleCount += newCount;
    [caller audioArrivedFromMike];
    if ([self updateAudioSpectrumData]) {
        [caller spectrumChanged];
    }
}

// add new data to audio spectrum

- (BOOL) updateAudioSpectrumData {
    float t = (float)sampleCount;
    // nch = 1;
 //   size_t fs = sampleRate;
    size_t nblk = floor(t*2.0/(float)FFT_LEN - 1);
//    NSLog(@"freq resolution is %.0f at sampling rate %zuHz, nblk=%zu bc=%zu",
//          (float)fs/FFT_LEN, fs, nblk, blockCount);

    //    Selection *selection = [selections objectAtIndex:0]; // for now
//    size_t nSegments = (targetWidth + (FFT_LEN - 1))/FFT_LEN;
//    NSLog(@"t = %.0f  alloc=%zu  nblk=%zu bc=%zu", t, blocksAlloc, nblk, blockCount);
    
    assert(blocksAlloc);
    if (nblk <= blockCount) // not enough yet
        return NO;
    
    if (nblk > blocksAlloc) {
        if (blockCount == blocksAlloc) {
            NSLog(@"****** FFT buffer full");
        }
        nblk = blocksAlloc;
    }
    if (blockCount == blocksAlloc) {    // full
        return NO;
    }
    
    size_t slen = FFT_LEN/2;
    size_t ftop = slen + 1;
    
    size_t blockStart = blockCount;
    
    for (size_t i = blockStart; i < nblk; i++) {
        if (blocks[i] == 0) {
            FFTBlock *b = calloc(ftop, sizeof(FFTBlock));
            assert(b);
            blocks[i] = b;
        }
        if (blockCount == blocksAlloc)
            break;
        else
            blockCount++;
    }
    
#ifdef OCTAVE
    resvec(1:ftop,1:blockCount)=0;
    
    for jj=1:blockCount
        t=x(((jj-1)*slen+1):((jj+1)*slen),ii);
        t=t .* wind;
        tt=fft(t);
        resvec(1:ftop,jj)=tt(1:ftop);
    end
    resvec=abs(resvec);
    tmp=max(max(resvec))+.0001; %no div0 please
    resvec=resvec/tmp;
    
    resvec=resvec+sqrt(0.0000000001); % limit lower end
    resvec=20*log10(resvec);
#endif
    FFTSetup FFTsetup = vDSP_create_fftsetup (round(log2(FFT_LEN)), kFFTRadix2);
    if (FFTsetup == 0) {
        NSLog(@"inconceivable, FFTSetup failed");
        return NO;
    }

    for (size_t s=blockStart; s<blockCount; s++) {
        float t[FFT_LEN], filtered[FFT_LEN];
        vDSP_vflt16(&samples[s*slen], 1, t, 1, FFT_LEN);
        vDSP_vmul(t, 1, hannFilter, 1, filtered, 1, FFT_LEN);
        
        float outReal[FFT_LEN / 2];
        float outImaginary[FFT_LEN / 2];
        COMPLEX_SPLIT out = {
            .realp = outReal,
            .imagp = outImaginary
        };
        vDSP_ctoz((DSPComplex *)filtered, 1, &out, 1, slen);
        assert(FFTsetup);
        vDSP_fft_zrip(FFTsetup, &out, 1, round(log2(FFT_LEN)), FFT_FORWARD);
        FFTBlock *block = blocks[s];
        vDSP_zvabs(&out, 1, block->raw, 1, slen);
        vDSP_maxv(block->raw, 1, &block->max, slen);
    }
    vDSP_destroy_fftsetup(FFTsetup);
    return YES;
}

// Generate the pixel data for the spectrogram

SpectrumPixel *pixelBuf = 0;
size_t pixelBufSize = 0;

- (NSData *) spectrumPixelDataForSize:(CGSize) size
                              options:(SpectrumOptions *)spectrumOptions
                             leftBlock:(size_t)leftBlock
                               startX:(int *)startX {
    size_t rightBlock = leftBlock + size.width/spectrumOptions.pixelsPerBlock;
    
    if (rightBlock > blockCount)
        rightBlock = blockCount;
    
    *startX = size.width - ((rightBlock - leftBlock)*spectrumOptions.pixelsPerBlock) - 1;
    assert(*startX >= 0 && *startX < size.width);
    
    for (size_t d=leftBlock; d<rightBlock; d++)
        if (!DBblocks[d])
            DBblocks[d] = (DBBlock *) malloc(sizeof(DBBlock));

    float max = FLT_MIN;
    for (size_t s=leftBlock; s<rightBlock; s++) {
        FFTBlock *block = blocks[s];
        max = MAX(max, block->max);
    }
    
    size_t slen = FFT_LEN/2;
    float minDB = FLT_MAX;
    float maxDB = FLT_MIN;

    // relative DB computation
    max += 0.0001;  // no div 0 please
    for (size_t b=leftBlock; b<rightBlock; b++) {
        FFTBlock *block = blocks[b];
        DBBlock *DBb = DBblocks[b];
        vDSP_vsdiv(block->raw, 1, &max, DBb->DB, 1, slen);     // R = R/max;
        float sm = sqrt(0.0000000001);            // limit lower end
        vDSP_vsadd(DBb->DB, 1, &sm, DBb->DB, 1, slen);      // R = R + tiny
        float one = 1.0;
        vDSP_vdbcon(DBb->DB, 1, &one, DBb->DB, 1, slen, 1);    // compute log10 db
        float min, max;
        vDSP_maxv(DBb->DB, 1, &max, slen);
//        for (int i=0; i<slen; i++)
//            NSLog(@"    %4d %5.1f", i, DBb->DB[i]);
        maxDB = MAX(maxDB, max);
        vDSP_minv(DBb->DB, 1, &min, slen);
        minDB = MIN(minDB, min);
    }
    
    size_t freqIncr = sampleRate/slen;
    size_t freqLow = spectrumOptions.minFreq/freqIncr;
    size_t freqHigh = spectrumOptions.maxFreq/freqIncr;
    size_t freqCount = freqHigh - freqLow;
    size_t pixelsPerFreq = size.height/freqCount;
    
    size_t bufSize = size.width * size.height * sizeof(SpectrumPixel);
    if (bufSize != pixelBufSize) {
        NSLog(@"new pixel buf size, from %zu to %zu", pixelBufSize, bufSize);
        pixelBufSize = bufSize;
        pixelBuf = (SpectrumPixel *)realloc(pixelBuf, pixelBufSize);
        assert(pixelBuf);
    }
    
    float range = maxDB - minDB;
    SpectrumPixel p;
    
#define BLACK   0
    memset(pixelBuf, BLACK, pixelBufSize);
    
    for (size_t y=0; y<size.height; y++) {
        // start of the y row.  NB: y is upside down
        size_t pyr = (size.height - y - 1) * size.width;
        size_t pxp = pyr + *startX*sizeof(SpectrumPixel);
        for (size_t b=leftBlock; b<rightBlock; b++) {
            float db = DBblocks[b]->DB[y];
            p = floor(((db - minDB)/range)*SPECTRUM_MAX_PIXEL);
            for (int i=0; i<spectrumOptions.pixelsPerBlock; i++)
                pixelBuf[pxp++] = p;
        }
        for (int j=1; j<pixelsPerFreq; j++) {
            y++;
            size_t npyr = (size.height - y - 1) * size.width;
            memcpy(&pixelBuf[npyr], &pixelBuf[pyr], size.width*sizeof(SpectrumPixel));
        }
    }
    NSData *pixelData = [NSData dataWithBytesNoCopy:pixelBuf length:bufSize freeWhenDone:NO];
    return pixelData;
}

- (void) close {
    if (samplesAlloced) {
        samplesAlloced = 0;
        free(samples);
    }
    sampleCount = 0;
    samples = nil;
    for (int i=0; i<blockCount; i++)
        if (blocks[i])
            free(blocks[i]);
}

@end
