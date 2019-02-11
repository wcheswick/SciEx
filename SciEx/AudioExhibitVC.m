//
//  AudioExhibitVC.m
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "AudioExhibitVC.h"

Sample *samples = 0;
size_t samples_alloc = 0;
size_t samples_len = 0;
size_t samples_start = 0;

@interface AudioExhibitVC ()

@property (nonatomic, strong)   AVAudioSession *session;
@property (nonatomic, strong)   AVCaptureSession *captureSession;
@property (nonatomic, strong)   AVCaptureDevice *audioDevice;
@property (nonatomic, strong)   AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong)   AVCaptureAudioDataOutput *audioDataOutput;
@property (assign)              float sampleRate;
@property (assign)              long mikeBlockNumber;

@end

@implementation AudioExhibitVC

@synthesize session, captureSession;
@synthesize audioDevice, audioInput;
@synthesize audioDataOutput;
@synthesize sampleRate, mikeBlockNumber;


- (id)init {
    self = [super init];
    if (self) {
        if (![self mikeAvailable])
            return nil;
        sampleRate = DEFAULT_SAMPLE_RATE;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (BOOL) mikeAvailable {
    AVCaptureDevice *audioDevice = [AVCaptureDevice
                                    defaultDeviceWithMediaType:AVMediaTypeAudio];
    return (audioDevice != nil);
}

// return error message or nil if it worked.

- (NSString *) startAudioCapture {
    NSError *error;
    
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat: 44100.0],                 AVSampleRateKey,
                              [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                              [NSNumber numberWithInt: 2],                         AVNumberOfChannelsKey,
                              [NSNumber numberWithInt: AVAudioQualityMax],         AVEncoderAudioQualityKey,
                              nil];

    session = [AVAudioSession sharedInstance];
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
    
    // We start capture session, even if we aren't saving at this point
    
    captureSession = [[AVCaptureSession alloc] init];
    audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    if (audioDevice == nil) {
        return @"microphone not available";
    }
    
    audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    [captureSession addInput:audioInput];
    
    audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    mikeBlockNumber = 0;

    dispatch_queue_t audioQueue = dispatch_queue_create("ProcessAudio", DISPATCH_QUEUE_SERIAL);
    [audioDataOutput setSampleBufferDelegate:self queue:audioQueue];
    
    [captureSession addOutput:audioDataOutput];
    [captureSession startRunning];
    return nil;
}

- (void) stopAudioCapture {
    [captureSession stopRunning];
}

@end
