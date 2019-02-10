//
//  AudioExhibitVC.h
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define DEFAULT_SAMPLE_RATE     44100
#define DEFAULT_SAMPLE_TYPE     short
#define RAW_SAMPLE_TYPE         short

@protocol AudioExhibitProto <NSObject>

- (void) newAudioData: (NSData *)buffer;
- (void) atEOFOrStopped;

@end

#import "ExhibitVC.h"

@interface AudioExhibitVC : ExhibitVC
<AVCaptureAudioDataOutputSampleBufferDelegate> {
    __unsafe_unretained id<AudioExhibitProto> caller;
}

@property (assign)      id<AudioExhibitProto>caller;

- (NSString *) startAudioCapture;
- (void) stopAudioCapture;
- (BOOL) mikeAvailable;

@end
