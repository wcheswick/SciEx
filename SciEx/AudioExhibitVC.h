//
//  AudioExhibitVC.h
//  SciEx
//
//  Created by ches on 1/31/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "ExhibitVC.h"
#import "AudioDefines.h"

@interface AudioExhibitVC : ExhibitVC
<AVCaptureAudioDataOutputSampleBufferDelegate>


- (NSString *) startAudioCapture;
- (void) stopAudioCapture;
- (BOOL) mikeAvailable;

@end
