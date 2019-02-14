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
<AVCaptureAudioDataOutputSampleBufferDelegate> {
    BOOL mikeIsOn;
}

@property (assign)              BOOL mikeIsOn;

- (NSString *) setupMike;
- (void) mikeOn:(BOOL) on;
- (BOOL) mikeAvailable;

@end
