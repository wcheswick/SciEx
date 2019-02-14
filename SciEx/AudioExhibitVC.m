//
//  AudioExhibitVC.m
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "AudioExhibitVC.h"

Sample *samples = 0;
size_t samples_alloc = 0;   // sample count, not byte count
size_t samples_count = 0;   // sample count, not byte count

@interface AudioExhibitVC ()

@property (nonatomic, strong)   AVCaptureSession *captureSession;
@property (nonatomic, strong)   AVCaptureDevice *audioDevice;
@property (nonatomic, strong)   AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong)   AVCaptureAudioDataOutput *audioDataOutput;
@property (assign)              float sampleRate;

@end

@implementation AudioExhibitVC

@synthesize captureSession;
@synthesize audioDevice, audioInput;
@synthesize audioDataOutput;
@synthesize sampleRate;
@synthesize mikeIsOn;

- (id)init {
    self = [super init];
    if (self) {
        sampleRate = DEFAULT_SAMPLE_RATE;
        mikeIsOn = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (BOOL) mikeAvailable {
    return ([self mikeDevice] != nil);
}

- (AVCaptureDevice *) mikeDevice {
    AVCaptureDeviceDiscoverySession *ds = [AVCaptureDeviceDiscoverySession
                                           discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInMicrophone]
                                           mediaType:AVMediaTypeAudio
                                           position:AVCaptureDevicePositionUnspecified];
    if (ds.devices.count == 0)
        return nil;
    return (AVCaptureDevice *) [ds.devices objectAtIndex:0];
}

// return error message or nil if it worked.
- (NSString *) setupMike {
    NSError *error;
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession beginConfiguration];
    
    captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    AVCaptureDevice *microphoneDevice = [self mikeDevice];
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
    return nil;
}

- (void) mikeOn:(BOOL) on {
    mikeIsOn = on;
    if (on)
        [captureSession startRunning];
    else
        [captureSession stopRunning];
}

@end

#ifdef dreg
session = [AVAudioSession sharedInstance];

NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithFloat: 44100.0],                 AVSampleRateKey,
                          [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                          [NSNumber numberWithInt: 1],                         AVNumberOfChannelsKey,
                          [NSNumber numberWithInt: AVAudioQualityMax],         AVEncoderAudioQualityKey,
                          nil];
if (session == nil) {
    return @"no session available";
}

if (![session setActive:YES error:&error]) {
    return [NSString stringWithFormat:@"setActive: %@",
            [error localizedDescription]];
}

if (![session setCategory:AVAudioSessionCategoryRecord error:&error]) {
    return [NSString stringWithFormat:@"setCategory: %@",
            [error localizedDescription]];
}

if (![session setMode:AVAudioSessionModeMeasurement error:&error]) {
    return [NSString stringWithFormat:@"setMode: %@",
            [error localizedDescription]];
}

if (![session setMode:AVAudioSessionModeMeasurement error:&error]){
    return [NSString stringWithFormat:@"setMode: %@",
            [error localizedDescription]];
}

if (![session setPreferredSampleRate:DEFAULT_SAMPLE_RATE error:&error]){
    return [NSString stringWithFormat:@"setPreferredSampleRate: %@",
            [error localizedDescription]];
}

if (![session setPreferredIOBufferDuration: 0.050 error:&error]) {
    return [NSString stringWithFormat:@"setPreferredIOBufferDuration: %@",
            [error localizedDescription]];
}

#ifdef notdef
if (![session setCategory:AVAudioSessionCategorySoloAmbient
              withOptions: AVAudioSessionCategoryOptionAllowBluetooth
                    error:&error]){
    return [NSString stringWithFormat:@"setCategory AVAudioSessionCategorySoloAmbient: %@",
            [error localizedDescription]];
}
#endif

if (![session setInputGain:1.0 error:&error]){
    return [NSString stringWithFormat:@"setInputGain: %@",
            [error localizedDescription]];
}
#endif

