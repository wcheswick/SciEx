#ifdef dreg
//
//  AudioExhibitVC.m
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "AudioExhibitVC.h"

@interface AudioExhibitVC ()

@end

@implementation AudioExhibitVC


- (id)init {
    self = [super init];
    if (self) {
        mikeIsOn = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

#endif

